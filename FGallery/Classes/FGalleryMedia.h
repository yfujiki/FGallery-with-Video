//
//  FGalleryMedia.h
//  TNF_Trails
//
//  Created by Grant Davis on 5/20/10. Modified by Yuichi Fujiki on 10/05/11.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum { 
    FGalleryMediaTypeImage,
    FGalleryMediaTypeVideo
} FGalleryMediaType;

@protocol FGalleryMediaDelegate;

@interface FGalleryMedia : NSObject {
	
	// value which determines if the Media was initialized with local file paths or network paths.
	BOOL _useNetwork;
	
	BOOL _isThumbLoading;
	BOOL _hasThumbLoaded;
	
	BOOL _isFullsizeLoading;
	BOOL _hasFullsizeLoaded;
		
	NSString *_thumbUrl;
	NSString *_fullsizeUrl;
	
	UIImage * _thumbnail;
	UIImage * _fullsizeImage;
    NSURL * _fullsizeVideoUrl;
	
	NSObject <FGalleryMediaDelegate> *__unsafe_unretained _delegate;
	
	NSUInteger tag;
    
    FGalleryMediaType _type;
}


- (id)initWithThumbnailUrl:(NSString*)thumb fullsizeUrl:(NSString*)fullsize type:(FGalleryMediaType)type delegate:(NSObject<FGalleryMediaDelegate>*)delegate;
- (id)initWithThumbnailPath:(NSString*)thumb fullsizePath:(NSString*)fullsize type:(FGalleryMediaType)type delegate:(NSObject<FGalleryMediaDelegate>*)delegate;

- (void)loadThumbnail;
- (void)loadFullsize;

- (void)unloadFullsize;
- (void)unloadThumbnail;

@property NSUInteger tag;

@property (readonly) BOOL isThumbLoading;
@property (readonly) BOOL hasThumbLoaded;

@property (readonly) BOOL isFullsizeLoading;
@property (readonly) BOOL hasFullsizeLoaded;

@property (strong, nonatomic,readonly) UIImage *thumbnail;
@property (strong, nonatomic,readonly) UIImage *fullsizeImage;

@property (nonatomic,unsafe_unretained) NSObject<FGalleryMediaDelegate> *delegate;

@property (readonly) FGalleryMediaType type;

@end


@protocol FGalleryMediaDelegate

@required
- (void)galleryMedia:(FGalleryMedia*)media didLoadThumbnail:(UIImage*)image;
- (void)galleryMedia:(FGalleryMedia*)media didLoadFullsizeImage:(UIImage*)image;
- (void)galleryMedia:(FGalleryMedia*)media didLoadFullsizeVideo:(NSURL*)url;

@optional
- (void)galleryMedia:(FGalleryMedia*)media willLoadThumbnailFromUrl:(NSString*)url;
- (void)galleryMedia:(FGalleryMedia*)media willLoadFullsizeFromUrl:(NSString*)url;

- (void)galleryMedia:(FGalleryMedia*)media willLoadThumbnailFromPath:(NSString*)path;
- (void)galleryMedia:(FGalleryMedia*)media willLoadFullsizeFromPath:(NSString*)path;

@end
