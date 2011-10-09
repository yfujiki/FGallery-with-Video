//
//  FGalleryPhotoView.h
//  TNF_Trails
//
//  Created by Grant Davis on 5/19/10. Modified by Yuichi Fujiki on 10/05/11.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@protocol FGalleryPhotoViewDelegate;

//@interface FGalleryPhotoView : UIImageView {
@interface FGalleryPhotoView : UIScrollView <UIScrollViewDelegate> {
	
	UIImageView * imageView;
	UIActivityIndicatorView * _activity;
	UIButton * _button;
	BOOL _isZoomed;
	NSTimer *_tapTimer;
	NSObject <FGalleryPhotoViewDelegate> *__unsafe_unretained photoDelegate;
}

- (void)killActivityIndicator;

// inits this view to have a button over the image
- (id)initWithFrame:(CGRect)frame target:(id)target action:(SEL)action;

- (void)resetZoom;

@property (nonatomic,unsafe_unretained) NSObject <FGalleryPhotoViewDelegate> *photoDelegate;
@property (strong, nonatomic,readonly) UIImageView *imageView;
@property (strong, nonatomic,readonly) UIButton *button;
@property (strong, nonatomic,readonly) UIActivityIndicatorView *activity;

@end



@protocol FGalleryPhotoViewDelegate

// indicates single touch and allows controller repsond and go toggle fullscreen
- (void)didTapPhotoView:(FGalleryPhotoView*)photoView;

@end

