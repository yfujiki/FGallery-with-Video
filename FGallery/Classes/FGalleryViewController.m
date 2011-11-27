//
//  FGalleryViewController.m
//  TNF_Trails
//
//  Created by Grant Davis on 5/19/10. Modified by Yuichi Fujiki on 10/05/11.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//
//	TODO: Fade out toolbar on image tap
//	TODO: Add fullscreen button?
//	TODO: Add rotation support

#import "FGalleryViewController.h"
#import "AVFoundation/AVFoundation.h"

#define kThumbnailSize 75
#define kThumbnailSpacing 4
#define kCaptionPadding 3
#define kToolbarHeight 40


@interface FGalleryViewController (Private)

// general
- (void)buildViews;

- (void)layoutViews;
- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation;
- (void)updateTitle;
- (void)updateButtons;
- (void)layoutButtons;
- (void)updateScrollSize;
- (void)updateCaption;
- (void)resizeMediaViewsWithRect:(CGRect)rect;
- (void)resetImageViewZoomLevels;

- (void)enterFullscreen;
- (void)exitFullscreen;
- (void)enableApp;
- (void)disableApp;

- (void)positionInnerContainer;
- (void)positionScroller;
- (void)positionToolbar;
- (void)resizeThumbView;

// thumbnails
- (void)toggleThumbView;
- (void)buildThumbsViewPhotos;

- (void)toggleFullScreen;

- (void)arrangeThumbs;
- (void)loadAllThumbViewPhotos;

- (void)preloadThumbnailImages;

- (void)fadeOutThumbView;
- (void)fadeInThumbView;
- (void)fadeOutInnerContainer;
- (void)fadeInInnerContainer;
- (void)curlThumbView;
- (void)uncurlThumbView;

- (void)unloadFullsizeMediaWithIndex:(NSUInteger)index;

- (void)scrollingHasEnded;

- (void)handleSeeAllTouch:(id)sender;
- (void)handleThumbClick:(id)sender;

- (FGalleryMedia*)createGalleryMediaForIndex:(NSUInteger)index;

- (void)loadThumbnailImageWithIndex:(NSUInteger)index;
- (void)loadFullsizeMediaWithIndex:(NSUInteger)index;

@end



@implementation FGalleryViewController
@synthesize galleryID;
@synthesize mediaSource = _mediaSource, currentIndex = _currentIndex, thumbsView = _thumbsView, toolBar = _toolbar;


#pragma mark - Public Methods


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if((self = [super initWithNibName:nil bundle:nil])) {
	
		// init gallery id with our memory address
		self.galleryID						= [NSString stringWithFormat:@"%p", self];
		
		// hide any silly bottom bars.
		self.hidesBottomBarWhenPushed		= YES;
		
		_prevStatusStyle					= [[UIApplication sharedApplication] statusBarStyle];
		
		// create storage
		_currentIndex						= 0;
		_mediaLoaders						= [[NSMutableDictionary alloc] init];
		_photoViews							= [[NSMutableDictionary alloc] init];
        _videoViews                         = [[NSMutableDictionary alloc] init];
		_photoThumbnailViews				= [[NSMutableDictionary alloc] init];
		_barItems							= [[NSMutableArray alloc] init];
		
		// create public objects first so they're available for custom configuration right away. positioning comes later.
		_container							= [[UIView alloc] initWithFrame:CGRectZero];
		_innerContainer						= [[UIView alloc] initWithFrame:CGRectZero];
		_scroller							= [[UIScrollView alloc] initWithFrame:CGRectZero];
		_thumbsView							= [[UIScrollView alloc] initWithFrame:CGRectZero];
		_toolbar							= [[UIToolbar alloc] initWithFrame:CGRectZero];
		_captionContainer					= [[UIView alloc] initWithFrame:CGRectZero];
		_caption							= [[UILabel alloc] initWithFrame:CGRectZero];
		
		_toolbar.barStyle					= UIBarStyleBlackTranslucent;
		
		_container.backgroundColor			= [UIColor blackColor];
		
		// listen for container frame changes so we can properly update the layout during auto-rotation or going in and out of fullscreen
		[_container addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
		
		/*
		// debugging: 
		_container.layer.borderColor = [[UIColor yellowColor] CGColor];
		_container.layer.borderWidth = 1.0;
		
		_innerContainer.layer.borderColor = [[UIColor greenColor] CGColor];
		_innerContainer.layer.borderWidth = 1.0;
		
		_scroller.layer.borderColor = [[UIColor redColor] CGColor];
		_scroller.layer.borderWidth = 2.0;
		*/
		
		// setup scroller
		_scroller.delegate							= self;
		_scroller.pagingEnabled						= YES;
		_scroller.showsVerticalScrollIndicator		= NO;
		_scroller.showsHorizontalScrollIndicator	= NO;
		
		// setup caption
		_captionContainer.backgroundColor			= [UIColor colorWithWhite:0.0 alpha:.35];
		_captionContainer.hidden					= YES;
		_captionContainer.userInteractionEnabled	= NO;
		_captionContainer.exclusiveTouch			= YES;
		_caption.font								= [UIFont systemFontOfSize:14.0];
		_caption.textColor							= [UIColor whiteColor];
		_caption.backgroundColor					= [UIColor clearColor];
		_caption.textAlignment						= UITextAlignmentCenter;
		_caption.shadowColor						= [UIColor blackColor];
		_caption.shadowOffset						= CGSizeMake( 1, 1 );
		
		// make things flexible
		_container.autoresizesSubviews				= NO;
		_innerContainer.autoresizesSubviews			= NO;
		_scroller.autoresizesSubviews				= NO;
		_container.autoresizingMask					= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		// setup thumbs view
		_thumbsView.backgroundColor					= [UIColor whiteColor];
		// _thumbsView.hidden							= YES;
        _thumbsView.alpha                           = 1.0;
		_thumbsView.contentInset					= UIEdgeInsetsMake( kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing);
	}
	return self;
}


- (id)initWithMediaSource:(NSObject<FGalleryViewControllerDelegate>*)mediaSrc
{
	if((self = [self initWithNibName:nil bundle:nil])) {
		
		_mediaSource = mediaSrc;
	}
	return self;
}


- (id)initWithMediaSource:(NSObject<FGalleryViewControllerDelegate>*)mediaSrc barItems:(NSArray*)items
{
	if((self = [self initWithMediaSource:mediaSrc])) {
		
		[_barItems addObjectsFromArray:items];
	}
	return self;
}


- (void)loadView
{
	// setup container
	self.view = _container;
	
	// add items to their containers
	[_container addSubview:_innerContainer];
	[_container addSubview:_thumbsView];
	
	[_innerContainer addSubview:_scroller];
	[_innerContainer addSubview:_toolbar];
	
	[_toolbar addSubview:_captionContainer];
	[_captionContainer addSubview:_caption];
	
	// create buttons for toolbar
	UIImage *leftIcon = [UIImage imageNamed:@"photo-gallery-left.png"];
	UIImage *rightIcon = [UIImage imageNamed:@"photo-gallery-right.png"];
	_nextButton = [[UIBarButtonItem alloc] initWithImage:rightIcon style:UIBarButtonItemStylePlain target:self action:@selector(next)];
	_prevButton = [[UIBarButtonItem alloc] initWithImage:leftIcon style:UIBarButtonItemStylePlain target:self action:@selector(previous)];
	
	// add prev next to front of the array
	[_barItems insertObject:_nextButton atIndex:0];
	[_barItems insertObject:_prevButton atIndex:0];
	
	_prevNextButtonSize = leftIcon.size.width;
	
	// set buttons on the toolbar.
	[_toolbar setItems:_barItems animated:NO];
		
	// create layer for the thumbnails
	_isThumbViewShowing = NO;
	
	// create the image views for each photo
	[self buildViews];
	
	// create the thumbnail views
	[self buildThumbsViewPhotos];
	
	// start loading thumbs
	[self preloadThumbnailImages];
    
    [self toggleThumbView];    
}




- (void)viewWillAppear:(BOOL)animated
{
//	NSLog(@"<ViewWillAppear>");
	_isActive = YES;
	
	[super viewWillAppear:animated]; // according to docs, we have to call this.
	
    _origNavigationBarTranslucent = [self.navigationController.navigationBar isTranslucent];
    _origNavigationBarTintColor = [self.navigationController.navigationBar tintColor];
	[self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    
	[self layoutViews];
	
	// update status bar to be see-through
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
	
	// init with next on first run.
	if( _currentIndex == -1 ) [self next];
	else [self gotoMediaByIndex:_currentIndex animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    
	_isActive = NO;
	
	[super viewWillDisappear:animated];
	
    [self.navigationController.navigationBar setTranslucent:_origNavigationBarTranslucent];
    [self.navigationController.navigationBar setTintColor:_origNavigationBarTintColor];
    
	[[UIApplication sharedApplication] setStatusBarStyle:_prevStatusStyle animated:animated];
}


- (void)resizeMediaViewsWithRect:(CGRect)rect
{
    NSUInteger i, count = [_mediaSource numberOfMediasForGallery:self];
	for (i = 0; i < count; i++) {        
        float xoffset = i * rect.size.width;
        if([_mediaSource mediaGallery:self mediaTypeForMediaAtIndex:i] == FGalleryMediaTypeImage)
        {
            FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
            photoView.frame = CGRectMake(xoffset, 0, rect.size.width, rect.size.height );
        }
        else
        {
            FGalleryVideoView * videoView = [_videoViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
            videoView.frame = CGRectMake(xoffset, 0, rect.size.width, rect.size.height );            
        }
	}
}

- (void)resetImageViewZoomLevels
{
	// resize all the image views
    uint i, count = _photoViews.count;
    for (i = 0; i<count; i++) {
        FGalleryPhotoView * photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
		[photoView resetZoom];
	}
}


- (void)removeImageAtIndex:(NSUInteger)index
{
	// remove the image and thumbnail at the specified index.
	FGalleryMedia *media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i",index]];	
	[media unloadFullsize];
	[media unloadThumbnail];
	
	FGalleryPhotoView *imgView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    FGalleryPhotoView *thumbView = [_photoThumbnailViews objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    FGalleryVideoView *videoView = [_videoViews objectForKey:[NSNumber numberWithUnsignedInteger:index]];    
	[imgView removeFromSuperview];
	[thumbView removeFromSuperview];
	[videoView removeFromSuperview];
    
	[_photoViews removeObjectForKey:[NSNumber numberWithUnsignedInteger:index]];
	[_photoThumbnailViews removeObjectForKey:[NSNumber numberWithUnsignedInteger:index]];
    [_videoViews removeObjectForKey:[NSNumber numberWithUnsignedInteger:index]];
	[_mediaLoaders removeObjectForKey:[NSString stringWithFormat:@"%i",index]];
	
	[self layoutViews];
	[self updateButtons];
    [self updateTitle];
}


- (void)next
{
	NSUInteger numberOfPhotos = [_mediaSource numberOfMediasForGallery:self];
	NSUInteger nextIndex = _currentIndex+1;
	
	// don't continue if we're out of images.
	if( nextIndex >= numberOfPhotos )
	{
		return;
	}
	
	[self gotoMediaByIndex:nextIndex animated:NO];
}



- (void)previous
{
	NSUInteger prevIndex = _currentIndex-1;
    
//	// don't continue if we're out of images.    
//    if( prevIndex < 0)
//    {
//        return;
//    }
    
	[self gotoMediaByIndex:prevIndex animated:NO];
}



- (void)gotoMediaByIndex:(NSUInteger)index animated:(BOOL)animated
{
//	NSLog(@"gotoImageByIndex: %i, out of %i", index, [_mediaSource numberOfPhotosForPhotoGallery:self]);
	
	NSUInteger numMedias = [_mediaSource numberOfMediasForGallery:self];
	
	// constrain index within our limits
    if( index >= numMedias ) index = numMedias - 1;
	
	
	if( numMedias == 0 ) {
		
		// no photos!
		_currentIndex = -1;
	}
	else {
		
		// clear the fullsize image in the old photo
		[self unloadFullsizeMediaWithIndex:_currentIndex];
		
		_currentIndex = index;
		[self moveScrollerToCurrentIndexWithAnimation:animated];
		[self updateTitle];
		
		if( !animated )	{
			[self preloadThumbnailImages];
			[self loadFullsizeMediaWithIndex:index];
		}
	}
	[self updateButtons];
	[self updateCaption];
}





// adjusts size and positioning of everything
- (void)layoutViews
{
	[self positionInnerContainer];
	
	[self positionScroller];
	
	[self resizeThumbView];
	
	[self positionToolbar];
	
	[self updateScrollSize];
	
	[self updateCaption];
	
	[self resizeMediaViewsWithRect:_scroller.frame];
    
	[self layoutButtons];
	
    [self loadAllThumbViewPhotos];
    
	[self arrangeThumbs];
	
	[self moveScrollerToCurrentIndexWithAnimation:NO];
}




#pragma mark - Private Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"frame"]) 
    {
        [self layoutViews];
    }    
}


- (void)positionInnerContainer
{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	CGRect innerContainerRect = CGRectZero;
	
	if( self.interfaceOrientation == UIInterfaceOrientationPortrait )
	{
		innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.height, _container.frame.size.width, screenFrame.size.height );
	}
	else if( self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft 
			|| self.interfaceOrientation == UIInterfaceOrientationLandscapeRight )
	{
		innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.width, _container.frame.size.width, screenFrame.size.width );
	}
	
	_innerContainer.frame = innerContainerRect;
}

- (void)positionScroller
{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	CGRect scrollerRect = CGRectZero;
	
	if( self.interfaceOrientation == UIInterfaceOrientationPortrait )
	{
		scrollerRect = CGRectMake( 0, 0, screenFrame.size.width, screenFrame.size.height );
	}
	else if( self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft 
			|| self.interfaceOrientation == UIInterfaceOrientationLandscapeRight )
	{
		scrollerRect = CGRectMake( 0, 0, screenFrame.size.height, screenFrame.size.width );
	}
	
	_scroller.frame = scrollerRect; //= CGRectZero;
}

- (void)positionToolbar
{
	_toolbar.frame = CGRectMake( 0, _scroller.frame.size.height-kToolbarHeight, _scroller.frame.size.width, kToolbarHeight );
}


- (void)resizeThumbView
{
	_thumbsView.frame = CGRectMake( 0, 0, _container.frame.size.width, _container.frame.size.height );
}


- (void)enterFullscreen
{
	_isFullscreen = YES;
	
	[self disableApp];
    
	UIApplication* application = [UIApplication sharedApplication];
	if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden: YES withAnimation: UIStatusBarAnimationFade]; // 3.2+
	} else {
		[[UIApplication sharedApplication] setStatusBarHidden: YES animated:YES]; // 2.0 - 3.2
	}
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	[UIView beginAnimations:@"galleryOut" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(enableApp)];
	_toolbar.alpha = 0.0;
	_captionContainer.alpha = 0.0;
	[UIView commitAnimations];
}



- (void)exitFullscreen
{
	_isFullscreen = NO;
    
	[self disableApp];
    
	UIApplication* application = [UIApplication sharedApplication];
	if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade]; // 3.2+
	} else {
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; // 2.0 - 3.2
	}
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    
	[UIView beginAnimations:@"galleryIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(enableApp)];
	_toolbar.alpha = 1.0;
	_captionContainer.alpha = 1.0;
	[UIView commitAnimations];
}



- (void)enableApp
{
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}
- (void)disableApp
{
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (void)didTapPhotoView:(FGalleryPhotoView*)photoView
{
    [self toggleFullScreen];
}

- (void)didTapVideoView:(FGalleryVideoView*)videoView
{
    [self toggleFullScreen];
}

- (void) toggleFullScreen {
    // don't change when scrolling
	if( _isScrolling || !_isActive ) return;
	
	// toggle fullscreen.
	if( _isFullscreen == NO ) {
		
		[self enterFullscreen];
	}
	else {
		
		[self exitFullscreen];
	}
}

- (void)updateCaption
{
	if([_mediaSource numberOfMediasForGallery:self] > 0 )
	{
		if([_mediaSource respondsToSelector:@selector(photoGallery:captionForMediaAtIndex:)])
		{
			NSString *caption = [_mediaSource mediaGallery:self captionForMediaAtIndex:_currentIndex];
			
			if([caption length] > 0 )
			{
				float captionWidth = _container.frame.size.width-kCaptionPadding*2;
				CGSize textSize = [caption sizeWithFont:_caption.font];
				NSUInteger numLines = ceilf( textSize.width / captionWidth );
				NSInteger height = ( textSize.height + kCaptionPadding ) * numLines;
				
				_caption.numberOfLines = numLines;
				_caption.text = caption;
				
				NSInteger containerHeight = height+kCaptionPadding*2;
				_captionContainer.frame = CGRectMake(0, -containerHeight, _container.frame.size.width, containerHeight );
				_caption.frame = CGRectMake(kCaptionPadding, kCaptionPadding, captionWidth, height );
				
				// show caption bar
				_captionContainer.hidden = NO;
			}
			else {
				
				// hide it if we don't have a caption.
				_captionContainer.hidden = YES;
			}
		}
	}
}


- (void)updateScrollSize
{
	float contentWidth = _scroller.frame.size.width * [_mediaSource numberOfMediasForGallery:self];
	[_scroller setContentSize:CGSizeMake(contentWidth, _scroller.frame.size.height)];
}


- (void)updateTitle
{
    if(!_isThumbViewShowing)
        [self setTitle:[NSString stringWithFormat:@"%i of %i", _currentIndex+1, [_mediaSource numberOfMediasForGallery:self]]];
    else
        [self setTitle:@"Thumbnails"];
}



- (void)updateButtons
{
	_prevButton.enabled = ( _currentIndex <= 0 ) ? NO : YES;
	_nextButton.enabled = ( _currentIndex >= [_mediaSource numberOfMediasForGallery:self]-1 ) ? NO : YES;
}

- (void)layoutButtons
{
	NSUInteger buttonWidth = roundf( _toolbar.frame.size.width / [_barItems count] - _prevNextButtonSize * .5);
	
	// loop through all the button items and give them the same width
	NSUInteger i, count = [_barItems count];
	for (i = 0; i < count; i++) {
		UIBarButtonItem *btn = [_barItems objectAtIndex:i];
		btn.width = buttonWidth;
	}
	[_toolbar setNeedsLayout];
}

- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation
{
	int xp = _scroller.frame.size.width * _currentIndex;
	[_scroller scrollRectToVisible:CGRectMake(xp, 0, _scroller.frame.size.width, _scroller.frame.size.height) animated:animation];
	_isScrolling = animation;
}



- (void)handleSeeAllTouch:(id)sender
{
	// show thumb view
	[self toggleThumbView];
	
	// tell thumbs that havent loaded to load
	[self loadAllThumbViewPhotos];
}




// creates all the image views for this gallery
- (void)buildViews
{
	NSUInteger i, count = [_mediaSource numberOfMediasForGallery:self];
	for (i = 0; i < count; i++) {
    
        if([_mediaSource mediaGallery:self mediaTypeForMediaAtIndex:i] == FGalleryMediaTypeImage)
        {
            FGalleryPhotoView *photoView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero];
            photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            photoView.autoresizesSubviews = YES;
            photoView.photoDelegate = self;
            [_scroller addSubview:photoView];
            [_photoViews setObject:photoView forKey:[NSNumber numberWithUnsignedInteger:i]];
        }
        else
        {
            FGalleryVideoView * videoView = [[FGalleryVideoView alloc] initWithFrame:CGRectZero];
            videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            videoView.autoresizesSubviews = YES;
            videoView.videoDelegate = self;
            [_scroller addSubview:videoView];
            [_videoViews setObject:videoView forKey:[NSNumber numberWithUnsignedInteger:i]];            
        }
	}
}



- (void)buildThumbsViewPhotos
{
	NSUInteger i, count = [_mediaSource numberOfMediasForGallery:self];
	for (i = 0; i < count; i++) {
		
		FGalleryPhotoView *thumbView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero target:self action:@selector(handleThumbClick:)];
		[thumbView setContentMode:UIViewContentModeScaleAspectFill];
		[thumbView setClipsToBounds:YES];
		[thumbView setTag:i];
		[_thumbsView addSubview:thumbView];
		[_photoThumbnailViews setObject:thumbView forKey:[NSNumber numberWithUnsignedInteger:i]];
	}
}



- (void)arrangeThumbs
{
	float dx = 0.0;
	float dy = 0.0;
	// loop through all thumbs to size and place them
	NSUInteger i, count = [_photoThumbnailViews count];
	for (i = 0; i < count; i++) {
		FGalleryPhotoView *thumbView = [_photoThumbnailViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
		// [thumbView setBackgroundColor:[UIColor grayColor]];
        [thumbView setBackgroundColor:[UIColor blackColor]];
		
		// create new frame
		thumbView.frame = CGRectMake( dx, dy, kThumbnailSize, kThumbnailSize);
		
		// increment position
		dx += kThumbnailSize + kThumbnailSpacing;
		
		// check if we need to move to a different row
		if( dx + kThumbnailSize + kThumbnailSpacing > _thumbsView.frame.size.width - kThumbnailSpacing )
		{
			dx = 0.0;
			dy += kThumbnailSize + kThumbnailSpacing;
		}
	}

	// set the content size of the thumb scroller
	//[_thumbsView setContentSize:CGSizeMake( _thumbsView.frame.size.width - ( kThumbnailSpacing*2 ), dy + kThumbnailSize + kThumbnailSpacing )];    
    [_thumbsView setContentSize:CGSizeMake( _thumbsView.frame.size.width - ( kThumbnailSpacing*2 ), dy)];
    CGPoint offset = CGPointMake(-1 * _thumbsView.contentInset.left, -1 * _thumbsView.contentInset.top);
    _thumbsView.contentOffset = offset;
}



- (void)toggleThumbView
{
	if( !_isThumbViewShowing ) 
	{
		_isThumbViewShowing = YES;
		[self arrangeThumbs];

		// [self uncurlThumbView];
        [self fadeInThumbView];
        [self fadeOutInnerContainer];
        
		// [self.navigationItem.rightBarButtonItem setTitle:@"Done"];

        if( self.navigationController )
        {
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
        }
	}
	else 
	{
		_isThumbViewShowing = NO;
        
		// [self curlThumbView];
        [self fadeOutThumbView];
        [self fadeInInnerContainer];
        
        if( self.navigationController )
        {
            UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Thumbnails" style:UIBarButtonItemStyleBordered target:self action:@selector(handleSeeAllTouch:)];
            [self.navigationItem setRightBarButtonItem:btn animated:YES];
        }
	}
    [self updateTitle];    
}



- (void)curlThumbView
{
	// do curl animation
	[UIView beginAnimations:@"curl" context:nil];
	[UIView setAnimationDuration:.666];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
	[_thumbsView setHidden:YES];
	[UIView commitAnimations];
}



- (void)uncurlThumbView
{
	// do curl animation
	[UIView beginAnimations:@"uncurl" context:nil];
	[UIView setAnimationDuration:.666];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
	[_thumbsView setHidden:NO];
	[UIView commitAnimations];
}

- (void)fadeOutThumbView
{
	// do curl animation
	[UIView beginAnimations:@"fadeOutThumb" context:nil];
	[UIView setAnimationDuration:.666];
	_thumbsView.alpha = 0.0;
	[UIView commitAnimations];
}


- (void)fadeInThumbView
{
	// do curl animation
	[UIView beginAnimations:@"fadeInThumb" context:nil];
	[UIView setAnimationDuration:.666];
    _thumbsView.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)fadeOutInnerContainer
{
	// do curl animation
	[UIView beginAnimations:@"fadeOutInner" context:nil];
	[UIView setAnimationDuration:.666];
	_innerContainer.alpha = 0.0;
	[UIView commitAnimations];
}


- (void)fadeInInnerContainer
{
	// do curl animation
	[UIView beginAnimations:@"fadeInInner" context:nil];
	[UIView setAnimationDuration:.666];
    _innerContainer.alpha = 1.0;
	[UIView commitAnimations];
}


- (void)handleThumbClick:(id)sender
{
    NSLog(@"Thumbs content offset top : %f", _thumbsView.contentOffset.y);
    NSLog(@"Container view top : %f", _container.frame.origin.y);    
    NSLog(@"Thumbs view top : %f", _thumbsView.frame.origin.y);
	
    FGalleryPhotoView *photoView = (FGalleryPhotoView*)[(UIButton*)sender superview];
	[self toggleThumbView];
	[self gotoMediaByIndex:photoView.tag animated:NO];
}

#pragma mark - Image Loading


- (void)preloadThumbnailImages
{
	NSUInteger index = _currentIndex;
	NSUInteger count = [_photoThumbnailViews count];
	// make sure the images surrounding the current index have thumbs loading
	NSUInteger nextIndex = index + 1;
	NSUInteger prevIndex = index - 1;
	
	// the preload count indicates how many images surrounding the current photo will get preloaded.
	// a value of 2 at maximum would preload 4 images, 2 in front of and two behind the current image.
	NSUInteger preloadCount = 1;
	
	
	FGalleryMedia *media;
	
	
	// check to see if the current image thumb has been loaded
	media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( !media )
	{
//		NSLog(@"preloading current image thumbnail!");
		[self loadThumbnailImageWithIndex:index];
		media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	}
	else if( !media.hasThumbLoaded && !media.isThumbLoading )
		[media loadThumbnail];
	
	
	NSUInteger curIndex = prevIndex;
	while( curIndex > -1 && curIndex > prevIndex - preloadCount )
	{
		media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !media ) {
			[self loadThumbnailImageWithIndex:curIndex];
			media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		else if( !media.hasThumbLoaded && !media.isThumbLoading )
			[media loadThumbnail];
		
//		NSLog(@"prev thumbnail %i loading", photo.tag );
		
		curIndex--;
	}
	
	curIndex = nextIndex;
	while( curIndex < count && curIndex < nextIndex + preloadCount )
	{
		media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !media ) {
			[self loadThumbnailImageWithIndex:curIndex];
			media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		else if( !media.hasThumbLoaded && !media.isThumbLoading )
			[media loadThumbnail];
//		NSLog(@"next thumbnail %i loading", photo.tag );
		
		curIndex++;
	}
}

- (void)loadAllThumbViewPhotos
{
	NSUInteger i, count = [_mediaSource numberOfMediasForGallery:self];
	for (i=0; i < count; i++) {
		
		[self loadThumbnailImageWithIndex:i];
	}
}


- (void)loadThumbnailImageWithIndex:(NSUInteger)index
{
//	NSLog(@"loadThumbnailImageWithIndex: %i", index );
	
	FGalleryMedia *media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( media == nil )
		media = [self createGalleryMediaForIndex:index];
	
	[media loadThumbnail];
}



- (void)loadFullsizeMediaWithIndex:(NSUInteger)index
{
	FGalleryMedia *media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( media == nil )
		media = [self createGalleryMediaForIndex:index];
	
	[media loadFullsize];
}



- (void)unloadFullsizeMediaWithIndex:(NSUInteger)index
{
    FGalleryMedia * media = [_mediaLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
    [media unloadFullsize];
    
    if([_mediaSource mediaGallery:self mediaTypeForMediaAtIndex:index] == FGalleryMediaTypeImage)
    {
        FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:index]];
        photoView.imageView.image = media.thumbnail;        
    }
    else
    {
        FGalleryVideoView * videoView = [_videoViews objectForKey:[NSNumber numberWithUnsignedInteger:index]];
        [videoView pause];
    }
}



- (FGalleryMedia *)createGalleryMediaForIndex:(NSUInteger)index
{
	FGalleryMediaSourceType sourceType = [_mediaSource mediaGallery:self sourceTypeForMediaAtIndex:index];
    FGalleryMediaType mediaType = [_mediaSource mediaGallery:self mediaTypeForMediaAtIndex:index];
    
	FGalleryMedia *media;
	NSString *thumbPath;
	NSString *fullsizePath;
	
	if( sourceType == FGalleryMediaSourceTypeLocal )
	{
		thumbPath = [_mediaSource mediaGallery:self filePathForMediaSize:FGalleryMediaSizeThumbnail atIndex:index];
		fullsizePath = [_mediaSource mediaGallery:self filePathForMediaSize:FGalleryMediaSizeFullsize atIndex:index];
		media = [[FGalleryMedia alloc] initWithThumbnailPath:thumbPath fullsizePath:fullsizePath type:mediaType delegate:self];
	}
	else if( sourceType == FGalleryMediaSourceTypeNetwork )
	{
		thumbPath = [_mediaSource mediaGallery:self urlForMediaSize:FGalleryMediaSizeThumbnail atIndex:index];
		fullsizePath = [_mediaSource mediaGallery:self urlForMediaSize:FGalleryMediaSizeFullsize atIndex:index];
		media = [[FGalleryMedia alloc] initWithThumbnailUrl:thumbPath fullsizeUrl:fullsizePath type:mediaType delegate:self];
	}
	else 
	{
		// invalid source type, throw an error.
		[NSException raise:@"Invalid photo source type" format:@"The specified source type of %d is invalid", sourceType];
	}
	
	// assign the photo index
	media.tag = index;
	
	// store it
	[_mediaLoaders setObject:media forKey: [NSString stringWithFormat:@"%i", index]];
	
	return media;
}


- (void)scrollingHasEnded {
	
	_isScrolling = NO;
	
	NSUInteger newIndex = floor( _scroller.contentOffset.x / _scroller.frame.size.width );
	
	// don't proceed if the user has been scrolling, but didn't really go anywhere.
	if( newIndex == _currentIndex )
		return;
	
	// clear previous
	[self unloadFullsizeMediaWithIndex:_currentIndex];
	
	_currentIndex = newIndex;
	[self updateCaption];
	[self updateTitle];
	[self updateButtons];
	[self loadFullsizeMediaWithIndex:_currentIndex];
	[self preloadThumbnailImages];
}


#pragma mark - FGalleryPhoto Delegate Methods


- (void)galleryMedia:(FGalleryMedia*)media willLoadThumbnailFromPath:(NSString*)path
{
	// show activity indicator for large photo view
	FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
	[photoView.activity startAnimating];
	
	// show activity indicator for thumbail 
	if( _isThumbViewShowing ) {
		FGalleryPhotoView *thumb = [_photoThumbnailViews objectForKey:[NSNumber numberWithInt:media.tag]];
		[thumb.activity startAnimating];
	}
}

/*
- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromPath:(NSString*)path
{
//	NSLog(@"galleryPhoto:willLoadFullsizeFromPath: %@", path );
}
*/


- (void)galleryMedia:(FGalleryMedia *)media willLoadThumbnailFromUrl:(NSString*)url
{
//	NSLog(@"galleryPhoto:willLoadThumbnailFromUrl:");
	
	// show activity indicator for large photo view
	FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
	[photoView.activity startAnimating];
	
	// show activity indicator for thumbail 
	if( _isThumbViewShowing ) {
		FGalleryPhotoView *thumb = [_photoThumbnailViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
		[thumb.activity startAnimating];
	}
}

/*
- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromUrl:(NSString*)url
{
//	NSLog(@"galleryPhoto:willLoadFullsizeFromUrl:");
}
 */



- (void)galleryMedia:(FGalleryMedia *)media didLoadThumbnail:(UIImage*)image
{
	// grab the associated image view
	FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
	
	// if the gallery photo hasn't loaded the fullsize yet, set the thumbnail as its image.
	if( !media.hasFullsizeLoaded )
		photoView.imageView.image = media.thumbnail;

	[photoView.activity stopAnimating];
	
	// grab the thumbail view and set its image
	FGalleryPhotoView *thumbView = [_photoThumbnailViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
	thumbView.imageView.image = image;
	[thumbView.activity stopAnimating];
}



- (void)galleryMedia:(FGalleryMedia *)media didLoadFullsizeImage:(UIImage*)image
{
	// only set the fullsize image if we're currently on that image
	if( _currentIndex == media.tag )
	{
		FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
		photoView.imageView.image = media.fullsizeImage;
	}
	// otherwise, we don't need to keep this image around
	else [media unloadFullsize];
}


- (void)galleryMedia:(FGalleryMedia *)media didLoadFullsizeVideo:(NSURL *)videoUrl
{
	// only set the fullsize image if we're currently on that image
	if( _currentIndex == media.tag )
	{
        FGalleryVideoView * videoView = [_videoViews objectForKey:[NSNumber numberWithUnsignedInteger:media.tag]];
        
        if(!videoView.player) // Not loaded yet
        {        
            AVURLAsset * asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
            
            NSError * error;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"track" error:&error];
            
            
            if(status != AVKeyValueStatusLoaded) {
                AVPlayerItem * playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [[NSNotificationCenter defaultCenter] addObserver:videoView
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:playerItem];
                
                AVPlayer * player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
                [videoView setPlayer:player];        
            }
            else
            {
                NSLog(@"Asset loading failed : %@", [error localizedDescription]);
            }
        }
	}
	// otherwise, we don't need to keep this image around
	else [media unloadFullsize];
}


#pragma mark - UIScrollView Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	_isScrolling = YES;
}
 
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if( !decelerate )
	{
		[self scrollingHasEnded];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self scrollingHasEnded];
}



#pragma mark - Memory Management Methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	
	NSLog(@"[FGalleryViewController] didReceiveMemoryWarning! clearing out cached images...");
	// unload fullsize and thumbnail images for all our images except at the current index.
	NSArray *keys = [_mediaLoaders allKeys];
	NSUInteger i, count = [keys count];
	for (i = 0; i < count; i++) 
	{
		if( i != _currentIndex )
		{
			FGalleryMedia *media = [_mediaLoaders objectForKey:[keys objectAtIndex:i]];
			[media unloadFullsize];
			[media unloadThumbnail];
			
			// unload main image
			FGalleryPhotoView *photoView = [_photoViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
			photoView.imageView.image = nil;
			
            // unload main video... not necessary.
            
			// unload thumb tile
			photoView = [_photoThumbnailViews objectForKey:[NSNumber numberWithUnsignedInteger:i]];
			photoView.imageView.image = nil;
		}
	}
	
	
}

/*
- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
*/

- (void)dealloc {	
	
//	NSLog(@"FGalleryViewController dealloc");
	
	// remove KVO listener
	[_container removeObserver:self forKeyPath:@"frame"];
	
	// Cancel all photo loaders in progress
	NSArray *keys = [_mediaLoaders allKeys];
	NSUInteger i, count = [keys count];
	for (i = 0; i < count; i++) {
		FGalleryMedia *media = [_mediaLoaders objectForKey:[keys objectAtIndex:i]];
		media.delegate = nil;
		[media unloadThumbnail];
		[media unloadFullsize];
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	
	_mediaSource = nil;
    _caption = nil;
    _captionContainer = nil;
    _container = nil;
    _innerContainer = nil;
    _toolbar = nil;
    _thumbsView = nil;
    _scroller = nil;
	
	[_mediaLoaders removeAllObjects];
    _mediaLoaders = nil;
	
	[_barItems removeAllObjects];
	_barItems = nil;
	
	[_photoThumbnailViews removeAllObjects];
    _photoThumbnailViews = nil;
	
	[_photoViews removeAllObjects];
    _photoViews = nil;
    
    [_videoViews removeAllObjects];
    _videoViews = nil;
	
    _nextButton = nil;
    _prevButton = nil;
}


@end


/**
 *	This section overrides the auto-rotate methods for UINaviationController and UITabBarController 
 *	to allow the tab bar to rotate only when a FGalleryController is the visible controller. Sweet.
 */

@implementation UINavigationController (FGallery)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if( interfaceOrientation == UIInterfaceOrientationPortrait 
	   || interfaceOrientation == UIInterfaceOrientationLandscapeLeft 
	   || interfaceOrientation == UIInterfaceOrientationLandscapeRight )
	{
		// see if the current controller in the stack is a gallery
		if([self.visibleViewController isKindOfClass:[FGalleryViewController class]])
		{
			return YES;
		}
	}
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	// see if the current controller in the stack is a gallery
	if([self.visibleViewController isKindOfClass:[FGalleryViewController class]])
	{
		FGalleryViewController *galleryController = (FGalleryViewController*)self.visibleViewController;
		[galleryController resetImageViewZoomLevels];
	}
}

@end




@implementation UITabBarController (FGallery)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if( interfaceOrientation == UIInterfaceOrientationPortrait 
	   || interfaceOrientation == UIInterfaceOrientationLandscapeLeft 
	   || interfaceOrientation == UIInterfaceOrientationLandscapeRight )
	{
		// only return yes if we're looking at the gallery
		if( [self.selectedViewController isKindOfClass:[UINavigationController class]])
		{
			UINavigationController *navController = (UINavigationController*)self.selectedViewController;
			
			// see if the current controller in the stack is a gallery
			if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
			{
				return YES;
			}
		}
	}
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if([self.selectedViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*)self.selectedViewController;
		
		// see if the current controller in the stack is a gallery
		if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
		{
			FGalleryViewController *galleryController = (FGalleryViewController*)navController.visibleViewController;
			[galleryController resetImageViewZoomLevels];
		}
	}
}


@end



