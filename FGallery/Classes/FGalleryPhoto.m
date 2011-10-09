//
//  FGalleryPhoto.m
//  TNF_Trails
//
//  Created by Grant Davis on 5/20/10.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//

#import "FGalleryPhoto.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "Reachability.h"

@interface FGalleryPhoto (Private)

// delegate notifying methods
- (void)willLoadThumbFromUrl;
- (void)willLoadFullsizeFromUrl;
- (void)willLoadThumbFromPath;
- (void)willLoadFullsizeFromPath;
- (void)didLoadThumbnail;
- (void)didLoadFullsize;

// loading local images with threading
- (void)loadFullsizeInThread;
- (void)loadThumbnailInThread;

// cleanup
- (void)killThumbnailLoadObjects;
- (void)killFullsizeLoadObjects;
@end


@implementation FGalleryPhoto

- (void)loadFullsize
{
	if( _isFullsizeLoading || _hasFullsizeLoaded ) return;
	
	if( _useNetwork )
	{
		// notify delegate
		[self willLoadFullsizeFromUrl];
		
		_isFullsizeLoading = YES;
		
//        if(![[Reachability reachabilityForInternetConnection] isReachable])
//        {
//            NSData * responseData = [[ASIDownloadCache sharedCache] cachedResponseDataForURL:[NSURL URLWithString:_fullsizeUrl]];
//            _fullsize = [UIImage imageWithData:responseData];        
//            _isFullsizeLoading = NO;
//            _hasFullsizeLoaded = YES;
//            
//            if(_delegate)
//                [self didLoadFullsize];
//            
//            return;
//        }
        
        __unsafe_unretained ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:_fullsizeUrl]];
        
        [request setDownloadCache:[ASIDownloadCache sharedCache]];
        [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        
        [request setCompletionBlock:^{
            NSData * responseData = [request responseData];
            _fullsizeImage = [UIImage imageWithData:responseData];
            _isFullsizeLoading = NO;
            _hasFullsizeLoaded = YES;
            
            // notify delegate
           	[self didLoadFullsize];
        }];
        [request setFailedBlock:^{
            NSLog(@"Failed to load full size image : %@", [request.error localizedDescription]);
            _isFullsizeLoading = NO;
        }];
        
        [request startAsynchronous];

	}
	else
	{
		[self willLoadFullsizeFromPath];
		
		_isFullsizeLoading = YES;
		
		// spawn a new thread to load from disk
		[NSThread detachNewThreadSelector:@selector(loadFullsizeInThread) toTarget:self withObject:nil];
	}
}


- (void)loadFullsizeInThread
{
	@autoreleasepool {
	
		NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _fullsizeUrl];
		_fullsizeImage = [UIImage imageWithContentsOfFile:path];
		
		_hasFullsizeLoaded = YES;
		_isFullsizeLoading = NO;

		[self performSelectorOnMainThread:@selector(didLoadFullsize) withObject:nil waitUntilDone:YES];
	
	}
}


@end
