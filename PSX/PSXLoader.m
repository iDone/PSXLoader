//
//  PSXLoader.m
//  PSX
//
//  Created by Dan on 2016/12/11.
//    Copyright © 2016年 Makigumo. All rights reserved.
//

#import "PSXLoader.h"

@implementation PSXLoader {
    NSObject <HPHopperServices> *_services;
}

- (instancetype)initWithHopperServices:(NSObject <HPHopperServices> *)services {
    if (self = [super init]) {
        _services = services;
    }
    return self;
}

- (HopperUUID *)pluginUUID {
    return [_services UUIDWithString:@"4F15DEFF-1B73-4538-8579-ABD75456F899"];
}

- (HopperPluginType)pluginType {
    return Plugin_Loader;
}

- (NSString *)pluginName {
    return @"PSX";
}

- (NSString *)pluginDescription {
    return @"PSX Loader";
}

- (NSString *)pluginAuthor {
    return @"Makigumo";
}

- (NSString *)pluginCopyright {
    return @"©2016 - Makigumo";
}

- (NSString *)pluginVersion {
    return @"0.0.1";
}

- (CPUEndianess)endianess {
    return CPUEndianess_Little;
}

- (BOOL)canLoadDebugFiles {
    return NO;
}

// Returns an array of DetectedFileType objects.
- (NSArray<DetectedFileType *> *)detectedTypesForData:(NSData *)data {
    if ([data length] < 4) return @[];

    const void *bytes = [data bytes];
    if (strncmp((const char *) bytes, "PS-X EXE", 8) == 0 ||
            strncmp((const char *) bytes, "SCE EXE", 7) == 0) {
        NSObject <HPDetectedFileType> *type = [_services detectedType];
        [type setFileDescription:@"PSX Executable"];
        [type setAddressWidth:AW_32bits];
        [type setCpuFamily:@"mips"];
        [type setCpuSubFamily:@"mips32"];
        [type setShortDescriptionString:@"psx_exe"];
        return @[type];
    }

    return @[];
}

- (FileLoaderLoadingStatus)loadData:(NSData *)data
              usingDetectedFileType:(DetectedFileType *)fileType
                            options:(FileLoaderOptions)options
                            forFile:(NSObject <HPDisassembledFile> *)file
                      usingCallback:(FileLoadingCallbackInfo)callback {
    const void *bytes = [data bytes];
    const PsxHeader *header = (PsxHeader *) bytes;
    if (strncmp((const char *) header->psx.id, "PS-X EXE", 8) == 0) {

        [_services logMessage:[NSString stringWithFormat:@"Creating section of %u bytes at [0x%x;0x%x[",
                                                         header->psx.t_size, header->psx.t_addr, header->psx.t_addr + header->psx.t_size]];

        NSObject <HPSegment> *segment = [file addSegmentAt:header->psx.t_addr size:header->psx.t_size];
        NSObject <HPSection> *section = [segment addSectionAt:header->psx.t_addr size:header->psx.t_size];

        segment.segmentName = @"TEXT";
        section.sectionName = @"text";
        section.pureCodeSection = YES;

        NSString *comment = [NSString stringWithFormat:@"\n\nSection %@\n\n", segment.segmentName];
        [file setComment:comment atVirtualAddress:header->psx.t_addr reason:CCReason_Automatic];

        // data starts at 0x800
        NSData *segmentData = [NSData dataWithBytes:bytes + 0x800 length:header->psx.t_size];

        segment.mappedData = segmentData;
        section.fileOffset = 0x800;
        section.fileLength = header->psx.t_size;

        [file addEntryPoint:header->psx.pc0];
    } else if (strncmp((const char *) header->psx.id, "SCE EXE", 7) == 0) {

        [file addEntryPoint:header->sce.pc0];
    } else {
        return DIS_BadFormat;
    }

    file.cpuFamily = @"mips";
    file.cpuSubFamily = @"mips32";
    [file setAddressSpaceWidthInBits:32];


    return DIS_OK;
}

- (void)fixupRebasedFile:(NSObject <HPDisassembledFile> *)file withSlide:(int64_t)slide originalFileData:(NSData *)fileData {

}

- (FileLoaderLoadingStatus)loadDebugData:(NSData *)data forFile:(NSObject <HPDisassembledFile> *)file usingCallback:(FileLoadingCallbackInfo)callback {
    return DIS_NotSupported;
}

- (NSData *)extractFromData:(NSData *)data usingDetectedFileType:(NSObject <HPDetectedFileType> *)fileType returnAdjustOffset:(uint64_t *)adjustOffset {
    return nil;
}

@end