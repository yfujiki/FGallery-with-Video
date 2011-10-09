//
//  FGalleryMedia.m
//  TNF_Trails
//
//  Created by Grant Davis on 5/20/10. Modified by Yuichi Fujiki on 10/05/11.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//

#import "FGalleryMedia.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "Reachability.h"

@interface FGalleryMedia (Private)

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


@implementation FGalleryMedia
@synthesize tag;
@synthesize thumbnail = _thumbnail;
@synthesize fullsizeImage = _fullsizeImage;
@synthesize delegate = _delegate;
@synthesize isFullsizeLoading = _isFullsizeLoading;
@synthesize hasFullsizeLoaded = _hasFullsizeLoaded;
@synthesize isThumbLoading = _isThumbLoading;
@synthesize hasThumbLoaded = _hasThumbLoaded;
@synthesize type = _type;


- (id)initWithThumbnailUrl:(NSString*)thumb fullsizeUrl:(NSString*)fullsize type:(FGalleryMediaType)type delegate:(NSObject<FGalleryMediaDelegate>*)delegate
{
	self = [super init];
	_useNetwork = YES;
	_thumbUrl = thumb;
	_fullsizeUrl = fullsize;
    _type = type;
	_delegate = delegate;
	return self;
}

- (id)initWithThumbnailPath:(NSString*)thumb fullsizePath:(NSString*)fullsize type:(FGalleryMediaType)type delegate:(NSObject<FGalleryMediaDelegate>*)delegate
{
	self = [super init];
	
	_useNetwork = NO;
	_thumbUrl = thumb;
	_fullsizeUrl = fullsize;
    _type = type;
	_delegate = delegate;
	return self;
}


- (void)loadThumbnail
{
	if( _isThumbLoading || _hasThumbLoaded ) return;
	
	// load from network
	if( _useNetwork )
	{
		// notify delegate
		[self willLoadThumbFromUrl];
		
		_isThumbLoading = YES;
		
//        if(![[Reachability reachabilityForInternetConnection] isReachable])
//        {
//            NSData * responseData = [[ASIDownloadCache sharedCache] cachedResponseDataForURL:[NSURL URLWithString:_thumbUrl]];
//            _thumbnail = [UIImage imageWithData:responseData];    
//            _isThumbLoading = NO;
//            _hasThumbLoaded = YES;
//            
//            if(_delegate)
//                [self didLoadThumbnail];
//            
//            return;
//        }
        
        __unsafe_unretained ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:_thumbUrl]];
        
        [request setDownloadCache:[ASIDownloadCache sharedCache]];
        [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        
        [request setCompletionBlock:^{
            NSData * responseData = [request responseData];
            _thumbnail = [UIImage imageWithData:responseData];
            _isThumbLoading = NO;
            _hasThumbLoaded = YES;
            
            // notify delegate
           	[self didLoadThumbnail];
        }];
        [request setFailedBlock:^{
            NSLog(@"Failed to load thumbnail image : %@", [request.error localizedDescription]);
            _isThumbLoading = NO;            
        }];
        
        [request startAsynchronous];
	}
	
	// load from disk
	else {
		
		// notify delegate
		[self willLoadThumbFromPath];
		
		_isThumbLoading = YES;
		
		// spawn a new thread to load from disk
		[NSThread detachNewThreadSelector:@selector(loadThumbnailInThread) toTarget:self withObject:nil];
	}
}


- (void)loadFullsize
{
    if(_type == FGalleryMediaTypeImage)
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
    else if(_type == FGalleryMediaTypeVideo)
    {
        [self willLoadFullsizeFromUrl];
        
        _hasFullsizeLoaded = YES;
        _isFullsizeLoading = NO;
        
        if(_useNetwork)            
            _fullsizeVideoUrl = [NSURL URLWithString:_fullsizeUrl];
        else
            _fullsizeVideoUrl = [[NSBundle mainBundle] URLForResource:_fullsizeUrl withExtension:nil];
        
        [self didLoadFullsize];
    }
    return;
}


- (void)loadFullsizeInThread
{
    if(_type == FGalleryMediaTypeImage)
    {
        @autoreleasepool {
            
            NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _fullsizeUrl];
            _fullsizeImage = [UIImage imageWithContentsOfFile:path];
            
            _hasFullsizeLoaded = YES;
            _isFullsizeLoading = NO;
            
            [self performSelectorOnMainThread:@selector(didLoadFullsize) withObject:nil waitUntilDone:YES];
            
        }        
    }
    else if(_type == FGalleryMediaTypeVideo) 
    {
        
    }
    return;
}


- (void)loadThumbnailInThread
{
	@autoreleasepool {
	
		NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _thumbUrl];
		_thumbnail = [UIImage imageWithContentsOfFile:path];
		
		_hasThumbLoaded = YES;
		_isThumbLoading = NO;
		
		[self performSelectorOnMainThread:@selector(didLoadThumbnail) withObject:nil waitUntilDone:YES];
	
	}
}


- (void)unloadFullsize
{
//	[_fullsizeImageConnection cancel];
	[self killFullsizeLoadObjects];
	
	_isFullsizeLoading = NO;
	_hasFullsizeLoaded = NO;
	
	_fullsizeImage = nil;
}

- (void)unloadThumbnail
{
//	[_thumbConnection cancel];
	[self killThumbnailLoadObjects];
	
	_isThumbLoading = NO;
	_hasThumbLoaded = NO;
	
	_thumbnail = nil;
}

#pragma mark -
#pragma mark Delegate Notification Methods


- (void)willLoadThumbFromUrl
{
	if([_delegate respondsToSelector:@selector(galleryMedia:willLoadThumbnailFromUrl:)])
		[_delegate galleryMedia:self willLoadThumbnailFromUrl:_thumbUrl];
}


- (void)willLoadFullsizeFromUrl
{
	if([_delegate respondsToSelector:@selector(galleryMedia:willLoadFullsizeFromUrl:)])
		[_delegate galleryMedia:self willLoadFullsizeFromUrl:_fullsizeUrl];
}


- (void)willLoadThumbFromPath
{
	if([_delegate respondsToSelector:@selector(galleryMedia:willLoadThumbnailFromPath:)])
		[_delegate galleryMedia:self willLoadThumbnailFromPath:_thumbUrl];
}


- (void)willLoadFullsizeFromPath
{
	if([_delegate respondsToSelector:@selector(galleryMedia:willLoadFullsizeFromPath:)])
		[_delegate galleryMedia:self willLoadFullsizeFromPath:_fullsizeUrl];
}


- (void)didLoadThumbnail
{
//	FLog(@"gallery phooto did load thumbnail!");
	if([_delegate respondsToSelector:@selector(galleryMedia:didLoadThumbnail:)])
		[_delegate galleryMedia:self didLoadThumbnail:_thumbnail];
}


- (void)didLoadFullsize
{
    if(_type == FGalleryMediaTypeImage)
    {
        //	FLog(@"gallery phooto did load fullsize!");
        if([_delegate respondsToSelector:@selector(galleryMedia:didLoadFullsizeImage:)])
            [_delegate galleryMedia:self didLoadFullsizeImage:_fullsizeImage];
    }
    else if(_type == FGalleryMediaTypeVideo)
    {
        if([_delegate respondsToSelector:@selector(galleryMedia:didLoadFullsizeVideo:)])
            [_delegate galleryMedia:self didLoadFullsizeVideo:_fullsizeVideoUrl];        
    }
}


#pragma mark -
#pragma mark Memory Management


- (void)killThumbnailLoadObjects
{
	
//	_thumbConnection = nil;
//	_thumbData = nil;
}



- (void)killFullsizeLoadObjects
{
	
//	_fullsizeImageConnection = nil;
//	_fullsizeImageData = nil;
}



- (void)dealloc
{
//	NSLog(@"FGalleryMedia dealloc");
	
//	[_delegate release];
	_delegate = nil;
	
//	[_fullsizeImageConnection cancel];
//	[_thumbConnection cancel];
	[self killFullsizeLoadObjects];
	[self killThumbnailLoadObjects];
	
	_thumbUrl = nil;
	
	_fullsizeUrl = nil;
	
	_thumbnail = nil;
	
	_fullsizeImage = nil;
	
}


@end
