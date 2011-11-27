//
//  FGalleryViewController.h
//  TNF_Trails
//
//  Created by Grant Davis on 5/19/10. Modified by Yuichi Fujiki on 10/05/11.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FGalleryPhotoView.h"
#import "FGalleryVideoView.h"
#import "FGalleryMedia.h"
// #import "FGalleryMoviePlayerController.h"

typedef enum
{
	FGalleryMediaSizeThumbnail,
	FGalleryMediaSizeFullsize
} FGalleryMediaSize;

typedef enum
{
	FGalleryMediaSourceTypeNetwork,
	FGalleryMediaSourceTypeLocal
} FGalleryMediaSourceType;

@protocol FGalleryViewControllerDelegate;

@interface FGalleryViewController : UIViewController <UIScrollViewDelegate,FGalleryMediaDelegate,FGalleryPhotoViewDelegate, FGalleryVideoViewDelegate> {
	
	UIStatusBarStyle _prevStatusStyle;
	
	BOOL _isActive;
	
	BOOL _isFullscreen;
	
	BOOL _isScrolling;
	
	BOOL _isThumbViewShowing;
	
	float _prevNextButtonSize;
	
	CGRect _scrollerRect;
	
	NSString *galleryID;
	
	NSInteger _currentIndex;
	
	UIView *_container; // used as view for the controller
	
	UIView *_innerContainer; // sized and placed to be fullscreen within the container
	
	UIToolbar * _toolbar;
	
	UIScrollView * _thumbsView;
	
	UIScrollView *_scroller;
	
	UIView *_captionContainer;
	
	UILabel *_caption;
	
	NSMutableDictionary *_mediaLoaders;
	
	NSMutableArray *_barItems;
	
	NSMutableDictionary *_photoThumbnailViews;	
	NSMutableDictionary *_photoViews;    
    NSMutableDictionary *_videoViews;
	
	NSObject <FGalleryViewControllerDelegate> *__unsafe_unretained _mediaSource;
	
	UIBarButtonItem *_nextButton;
	
	UIBarButtonItem *_prevButton;
    
    BOOL _origNavigationBarTranslucent;
    UIColor * _origNavigationBarTintColor;
}

- (id)initWithMediaSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc;
- (id)initWithMediaSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc barItems:(NSArray*)items;


- (void)removeImageAtIndex:(NSUInteger)index;

- (void)next;
- (void)previous;
- (void)gotoMediaByIndex:(NSUInteger)index animated:(BOOL)animated;

@property (nonatomic,unsafe_unretained) NSObject<FGalleryViewControllerDelegate> *mediaSource;
@property (nonatomic,strong, readonly) UIToolbar *toolBar;
@property (nonatomic,strong, readonly) UIView* thumbsView;
@property NSInteger currentIndex;
@property (nonatomic,strong) NSString *galleryID;

@end



@protocol FGalleryViewControllerDelegate

@required
- (int)numberOfMediasForGallery:(FGalleryViewController*)gallery;
- (FGalleryMediaSourceType)mediaGallery:(FGalleryViewController*)gallery sourceTypeForMediaAtIndex:(NSUInteger)index;
- (FGalleryMediaType)mediaGallery:(FGalleryViewController*)gallery mediaTypeForMediaAtIndex:(NSUInteger)index;

@optional
- (NSString*)mediaGallery:(FGalleryViewController*)gallery captionForMediaAtIndex:(NSUInteger)index;

// the MediaSource must implement one of these methods depending on which FGalleryMediaSourceType is specified 
- (NSString*)mediaGallery:(FGalleryViewController*)gallery filePathForMediaSize:(FGalleryMediaSize)size atIndex:(NSUInteger)index;
- (NSString*)mediaGallery:(FGalleryViewController*)gallery urlForMediaSize:(FGalleryMediaSize)size atIndex:(NSUInteger)index;

@end
