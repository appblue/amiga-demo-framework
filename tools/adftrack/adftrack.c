#include <stdio.h>
#include <string.h>
#include <vector>
#include <iostream>

#define ULONG_MAX_32 0xffffffff

using namespace std;

// Structure for a file on disk
struct FileEntry {
    char*	filename;		// the filename
    int		startoffset;	// the starting offset on disk in bytes
    int		startblock;     // the starting offset on disk in blocks
    int		numblocks;		// the amount of blocks/sectors the file occupies on disk.

    FileEntry() {
        filename=0;
        startoffset=-1;
        startblock=-1;
        numblocks=0;
    }

    FileEntry( char* filename ) {
        this->filename=filename;
        this->startoffset=-1;
        this->startblock=-1;
        this->numblocks=0;
    }
};

// Swaps endianess of an integer
uint32_t BSwapInt( uint32_t value ) {
    uint32_t value2=(value<<24) | ((value & 0xff00)<<8) | ((value & 0xff0000)>>8) | (value>>24);

    return value2;
}

// Swaps endianess of an array of integers
void BSwapIntArray( unsigned int* values, int size ) {
    for (int i=0 ; i<size ; i++) {
        values[i]=BSwapInt(values[i]);
    }
}

// Calculate the checksum of the disk-bootblock and write it back to the disk-buffer
void PatchBootBlockCheckSum( unsigned char* buf ) {
    int i;
    uint32_t newsum, d;

    uint32_t* buf2=(uint32_t*)(buf);

    buf2[1]=0;		/* clear old checksum */

    newsum=0;

    for(i=0 ; i<256 ; i++) {
        d=BSwapInt(buf2[i]);
        if ( (ULONG_MAX_32-newsum) < d )	/* overflow */
            newsum++; 

        newsum+=d; 
    } 

    newsum=~newsum;		/* not */

    buf2[1]=BSwapInt(newsum);
}

// Adds a file to the diskbuffer
void AddFile( FileEntry& fileentry, unsigned char* buf, int& fileoffset ) {
    char* filename=fileentry.filename;

    cout << "adding file: " << filename << endl;

    // open file
    FILE* filer=fopen(filename, "rb");
    if(!filer) {
        printf("cannot open \"%s\"\n", filename);
        exit(-1);
    }

    // calc file size
    fseek(filer, 0, SEEK_END);
    int filesize=ftell(filer);
    fseek(filer, 0, SEEK_SET);

    if(filesize<=0) {
        printf("file \"%s\" is empty\n", filename);
        exit(-1);
    }

    int filesize_padded_to_blocks = 512*((filesize/512)+1);

    // add padding to be 32 bit aligned
    // int filesizepad=(filesize+3) & 0xfffffffc;

    // does the file fit onto the disk?
    int fileendoffset=fileoffset+filesize_padded_to_blocks;
    int freespace=901120-fileendoffset;
    if (freespace<0) {
        printf("couldnt find space for file \"%s\" - disk full!\n", filename);
        exit(-1);
    }

    // alloc mem and read file
    unsigned char* buf2=new unsigned char[filesize_padded_to_blocks];
    memset(buf2, 0, filesize_padded_to_blocks);

    fread(buf2, 1, filesize, filer);

    // write the file into the filebuf
    memcpy(buf+fileoffset, buf2, filesize_padded_to_blocks);

    cout << "free space: " << freespace << endl;

    // calc occupied blocks
    int startblock=fileoffset/512;
    int endblock=(fileendoffset-1)/512;
    int numblocks=(endblock-startblock)+1;

    // write info to the file-struct
    fileentry.startoffset=fileoffset;
    fileentry.startblock=fileoffset/512;
    fileentry.numblocks=numblocks;

    // free mem and close file
    delete [] buf2;

    fclose(filer);

    // return end of file offset for error handling
    fileoffset=fileendoffset;
}

////////////////////////////////////////////////////
// main function
////////////////////////////////////////////////////
int main(int argc, char **argv) {
    // if not enough params, show usage info
    if(argc < 3) {
        printf("usage %s <bootblock> <outfile> <mapfile> [n <filenames>]\n", argv[0]);
        exit(-1);
    }

    // get bootblock and adf filenames from commandline
    const char* bootname=argv[1];
    const char* filewname=argv[2];
    const char* mapname=argv[3];

    // open file containing bootblock
    FILE* bootfile=fopen(bootname, "rb");
    if(!bootfile) {
        printf("cannot open \"%s\"\n", bootname);
        exit(-1);
    }

    // calc bootblock size and reject if the bootblock is > 1kb
    fseek(bootfile, 0, SEEK_END);
    int bootsize=ftell(bootfile);
    fseek(bootfile, 0, SEEK_SET);
    if (bootsize>1024) {
        printf("\"%s\" has wrong filesize. a valid bootblock must be <= 1024 bytes.\n", bootname);
        exit(-1);
    }

    // create diskbuffer
    int filesize=901120;

    unsigned char* buf=new unsigned char[filesize];

    memset(buf, 0, filesize);

    // read bootblock into sectors 0 & 1
    fread(buf, 1, bootsize, bootfile);

    // patch the checksum of the bootblock
    PatchBootBlockCheckSum(buf);

    // get all input-files from the commandline and add them to the filestruct-list
    vector<FileEntry> files;

    int numfiles = argc - 4;

    for (int i=0 ; i<numfiles ; i++) {
        files.push_back((char*)argv[ i + 4 ]);
    }

    // reserve the first 3 sectors of the diskbuffer for bootblock and our directory
    int fileoffset=3*512;

    // add all files from the list to the diskbuffer
    for (int i=0 ; i<numfiles ; i++) {
        AddFile(files[i], buf, fileoffset);
    }

    //write our directory info

    // first in pc-format to an intermed buffer
    int mydirsector[128];

    memset(mydirsector, 0, sizeof(mydirsector));

    int* mydirpoi=mydirsector;

    // open file containing bootblock
    FILE* mapfile=fopen(mapname, "w+");
    if(!mapfile) {
        printf("cannot open \"%s\"\n", mapname);
        exit(-1);
    }

    for (int i=0 ; i<numfiles ; i++) {
        *mydirpoi++=(files[i].startblock);
        *mydirpoi++=files[i].numblocks;
        fprintf(mapfile, "%s_sblock = %d\n", files[i].filename, files[i].startblock);
        fprintf(mapfile, "%s_nblock = %d\n", files[i].filename, files[i].numblocks);

        printf("%s_sblock = %d\n", files[i].filename, files[i].startblock);
        printf("%s_nblock = %d\n", files[i].filename, files[i].numblocks);
    }

    fclose(mapfile);

    // correct endianess of the buffer
    BSwapIntArray((unsigned int*)(mydirsector), 128);

    // copy the directory info to sector 2 of the disk-buffer
    memcpy(buf+2*512, mydirsector, sizeof(mydirsector));

    // write the adf output file
    FILE* filew=fopen(filewname, "wb");
    if(!filew) {
        printf("cannot open \"%s\"\n", filewname);
        exit(-1);
    }

    fwrite(buf, 1, filesize, filew);

    // free memory and close all files
    delete [] buf;

    fclose(bootfile);
    fclose(filew);
}
