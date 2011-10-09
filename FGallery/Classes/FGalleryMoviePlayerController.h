//
//  FGalleryMoviePlayerViewController.h
//  FGallery
//
//  Created by Yuichi Fujiki on 10/7/11.
//  Copyright (c) Yuichi Fujiki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer/MPMoviePlayerController.h"

@interface FGalleryMoviePlayerController : MPMoviePlayerController {
    UIViewController * _parentController;
}

@property (nonatomic, retain) UIViewController * parentController;

-(id) initWithContentURL:(NSURL *) contentURL parentController:(UIViewController *)parentController;

- (void)handleSwipeToRight:(UISwipeGestureRecognizer *)recognizer;
- (void)handleSwipeToLeft:(UISwipeGestureRecognizer *)recognizer;

- (void)standby;
@end
