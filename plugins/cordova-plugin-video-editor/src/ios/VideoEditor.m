//
//  VideoEditor.m
//
//  Created by Josh Bavari on 01-14-2014
//  Modified by Ross Martin on 01-29-2015
//

#import <Cordova/CDV.h>
#import "VideoEditor.h"

@interface VideoEditor ()

@end

@implementation VideoEditor

/**
 * transcodeVideo
 *
 * Transcodes a video
 *
 * ARGUMENTS
 * =========
 *
 * fileUri:         - path to input video
 * outputFileName:  - output file name
 * quality:         - transcode quality
 * outputFileType:  - output file type
 * saveToLibrary:   - save to gallery
 * deleteInputFile: - optionally remove input file
 *
 * RESPONSE
 * ========
 *
 * outputFilePath - path to output file
 *
 * @param CDVInvokedUrlCommand command
 * @return void
 */
- (void) transcodeVideo:(CDVInvokedUrlCommand*)command
{
    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *assetPath = [options objectForKey:@"fileUri"];
    NSString *videoFileName = [options objectForKey:@"outputFileName"];
    
    CDVQualityType qualityType = ([options objectForKey:@"quality"]) ? [[options objectForKey:@"quality"] intValue] : LowQuality;
    
    NSString *presetName = Nil;
    
    switch(qualityType) {
        case HighQuality:
            presetName = AVAssetExportPresetHighestQuality;
            break;
        case MediumQuality:
        default:
            presetName = AVAssetExportPresetMediumQuality;
            break;
        case LowQuality:
            presetName = AVAssetExportPresetLowQuality;
    }

    CDVOutputFileType outputFileType = ([options objectForKey:@"outputFileType"]) ? [[options objectForKey:@"outputFileType"] intValue] : MPEG4;
    
    BOOL optimizeForNetworkUse = ([options objectForKey:@"optimizeForNetworkUse"]) ? [[options objectForKey:@"optimizeForNetworkUse"] intValue] : NO;
    
    float videoDuration = [[options objectForKey:@"duration"] floatValue];
    
    BOOL saveToPhotoAlbum = [options objectForKey:@"saveToLibrary"] ? [[options objectForKey:@"saveToLibrary"] boolValue] : YES;
    
    NSString *stringOutputFileType = Nil;
    NSString *outputExtension = Nil;
    
    switch (outputFileType) {
        case QUICK_TIME:
            stringOutputFileType = AVFileTypeQuickTimeMovie;
            outputExtension = @".mov";
            break;
        case M4A:
            stringOutputFileType = AVFileTypeAppleM4A;
            outputExtension = @".m4a";
            break;
        case M4V:
            stringOutputFileType = AVFileTypeAppleM4V;
            outputExtension = @".m4v";
            break;
        case MPEG4:
        default:
            stringOutputFileType = AVFileTypeMPEG4;
            outputExtension = @".mp4";
            break;
    }
    
    // remove file:// from the assetPath if it is there
    assetPath = [[assetPath stringByReplacingOccurrencesOfString:@"file://" withString:@""] mutableCopy];
    
    // check if the video can be saved to photo album before going further
    if (saveToPhotoAlbum && !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(assetPath))
    {
        NSString *error = @"Video cannot be saved to photo album";
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error ] callbackId:command.callbackId];
        return;
    }
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *tempVideoPath =[NSString stringWithFormat:@"%@/%@%@", docDir, videoFileName, @".mov"];
    NSData *videoData = [NSData dataWithContentsOfFile:assetPath];
    [videoData writeToFile:tempVideoPath atomically:NO];

    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:tempVideoPath] options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName: presetName];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *videoPath = [NSString stringWithFormat:@"%@/%@%@", [paths objectAtIndex:0], videoFileName, outputExtension];
        
        exportSession.outputURL = [NSURL fileURLWithPath:videoPath];
        exportSession.outputFileType = stringOutputFileType;
        exportSession.shouldOptimizeForNetworkUse = optimizeForNetworkUse;
        
        NSLog(@"videopath of your file: %@", videoPath);
        
        if (videoDuration)
        {
            int32_t preferredTimeScale = 600;
            CMTime startTime = CMTimeMakeWithSeconds(0, preferredTimeScale);
            CMTime stopTime = CMTimeMakeWithSeconds(videoDuration, preferredTimeScale);
            CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
            exportSession.timeRange = exportTimeRange;
        }

        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    if (saveToPhotoAlbum) {
                        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, nil, nil);
                    }
                    NSLog(@"Export Complete %d %@", exportSession.status, exportSession.error);
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:videoPath] callbackId:command.callbackId];
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[[exportSession error] localizedDescription]] callbackId:command.callbackId];
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"Export default in switch");
                    break;
            }
        }];
    }

}

/**
 * createThumbnail
 *
 * Creates a thumbnail from the start of a video.
 *
 * ARGUMENTS
 * =========
 * fileUri        - input file path
 * outputFileName - output file name
 *
 * RESPONSE
 * ========
 *
 * outputFilePath - path to output file
 *
 * @param CDVInvokedUrlCommand command
 * @return void
 */
- (void) createThumbnail:(CDVInvokedUrlCommand*)command
{
    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString* srcVideoPath = [options objectForKey:@"fileUri"];
    NSString* outputFileName = [options objectForKey:@"outputFileName"];
    
    NSString* outputFilePath = extractVideoThumbnail(srcVideoPath, outputFileName);
    
    if (outputFilePath != nil)
    {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputFilePath] callbackId:command.callbackId];
    }
    else
    {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:outputFilePath] callbackId:command.callbackId];
    }
}

/**
 * trim
 *
 * Performs a trim operation on a clip, while encoding it.
 *
 * ARGUMENTS
 * =========
 * fileUri        - input file path
 * trimStart      - time to start trimming
 * trimEnd        - time to end trimming
 * outputFileName - output file name
 *
 * RESPONSE
 * ========
 *
 * outputFilePath - path to output file
 *
 * @param CDVInvokedUrlCommand command
 * @return void
 */
- (void) trim:(CDVInvokedUrlCommand*)command {
    NSLog(@"[Trim]: trim called");
    
    // extract arguments
    NSDictionary* options = [command.arguments objectAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSString *inputFile = [options objectForKey:@"fileUri"];
    float trimStart = [[options objectForKey:@"trimStart"] floatValue];
    float trimEnd = [[options objectForKey:@"trimEnd"] floatValue];
    NSString *outputName = [options objectForKey:@"outputFileName"];
    
    // remove file:// from the inputFile path if it is there
    inputFile = [[inputFile stringByReplacingOccurrencesOfString:@"file://" withString:@""] mutableCopy];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    // videoDir
    NSString *videoDir = [cacheDir stringByAppendingPathComponent:@"mp4"];
    if ([fileMgr createDirectoryAtPath:videoDir withIntermediateDirectories:YES attributes:nil error: NULL] == NO){
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"failed to create video dir"] callbackId:command.callbackId];
        return;
    }
    NSString *videoOutput = [videoDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", outputName, @"mp4"]];
    
    NSLog(@"[Trim]: inputFile path: %@", inputFile);
    NSLog(@"[Trim]: outputPath: %@", videoOutput);
    
    // run in background
    [self.commandDelegate runInBackground:^{
        
        AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:inputFile] options:nil];
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName: AVAssetExportPresetHighestQuality];
        exportSession.outputURL = [NSURL fileURLWithPath:videoOutput];
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.shouldOptimizeForNetworkUse = NO;
        
        int32_t preferredTimeScale = 600;
        CMTime startTime = CMTimeMakeWithSeconds(trimStart, preferredTimeScale);
        CMTime stopTime = CMTimeMakeWithSeconds(trimEnd, preferredTimeScale);
        CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
        exportSession.timeRange = exportTimeRange;
        
        // debug timings
        NSString *trimStart = (NSString *) CFBridgingRelease(CMTimeCopyDescription(NULL, startTime));
        NSString *trimEnd = (NSString *) CFBridgingRelease(CMTimeCopyDescription(NULL, stopTime));
        NSLog(@"[Trim]: duration: %lld, trimStart: %@, trimEnd: %@", avAsset.duration.value, trimStart, trimEnd);
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"[Trim]: Export Complete %d %@", exportSession.status, exportSession.error);
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:videoOutput] callbackId:command.callbackId];
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"[Trim]: Export failed: %@", [[exportSession error] localizedDescription]);
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[[exportSession error] localizedDescription]] callbackId:command.callbackId];
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"[Trim]: Export canceled");
                    break;
                default:
                    NSLog(@"[Trim]: Export default in switch");
                    break;
            }
        }];
        
    }];
}

NSString* extractVideoThumbnail(NSString *srcVideoPath, NSString *outputFileName)
{
    
    UIImage *thumbnail;
    NSURL *url;
    
    NSLog(@"srcVideoPath: %@", srcVideoPath);
    
    if ([srcVideoPath rangeOfString:@"://"].location == NSNotFound)
    {
        url = [NSURL URLWithString:[[@"file://localhost" stringByAppendingString:srcVideoPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        url = [NSURL URLWithString:[srcVideoPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // http://stackoverflow.com/a/6432050
    MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:url];
    mp.shouldAutoplay = NO;
    mp.initialPlaybackTime = 1;
    mp.currentPlaybackTime = 1;
    // get the thumbnail
    thumbnail = [mp thumbnailImageAtTime:1 timeOption:MPMovieTimeOptionNearestKeyFrame];
    [mp stop];
    
    NSString *outputFilePath = [documentsPathForFileName(outputFileName) stringByAppendingString:@".jpg"];
    
    NSLog(@"path to your video thumbnail: %@", outputFilePath);
    
    // write out the thumbnail; a return of nil will be a failure.
    if ([UIImageJPEGRepresentation (thumbnail, 1.0) writeToFile:outputFilePath atomically:YES])
    {
        return outputFilePath;
    }
    else
    {
        return nil;
    }
}

NSString *documentsPathForFileName(NSString *name)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    return [documentsPath stringByAppendingPathComponent:name];
}

@end