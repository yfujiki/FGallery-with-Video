//
//  FGalleryMoviePlayerViewController.m
//  FGallery
//
//  Created by Yuichi Fujiki on 10/7/11.
//  Copyright (c) 2011 Yuichi Fujiki. All rights reserved.
//

#import "FGalleryMoviePlayerController.h"

@class FGalleryViewController;

@implementation FGalleryMoviePlayerController

@synthesize parentController = _parentController;

-(id) initWithContentURL:(NSURL *) contentURL parentController:(UIViewController *)parentController 
{
    if(self = [super initWithContentURL:contentURL])
    {
        _parentController = parentController;
        
        UISwipeGestureRecognizer * rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToRight:)];        
        rightSwipeRecognizer.numberOfTouchesRequired = 1;
        rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

        UISwipeGestureRecognizer * leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToLeft:)];        
        leftSwipeRecognizer.numberOfTouchesRequired = 1;
        leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

        [self.view addGestureRecognizer:rightSwipeRecognizer];
        [self.view addGestureRecognizer:leftSwipeRecognizer];        
    }
    return self;
}

- (void)standby 
{
    self.shouldAutoplay = NO;
    self.fullscreen = NO;
    // self.controlStyle = MPMovieControlStyleEmbedded;
    
    [self prepareToPlay];
}

- (void)handleSwipeToRight:(UISwipeGestureRecognizer *)recognizer
{
    NSLog(@"Swipe to right");
    
//    [self.view setHidden:YES]; // TODO some kind of animation
    
    if([_parentController respondsToSelector:@selector(previous)])
        [_parentController performSelectorOnMainThread:@selector(previous) withObject:nil waitUntilDone:YES];        
}

- (void)handleSwipeToLeft:(UISwipeGestureRecognizer *)recognizer
{
    NSLog(@"Swipe to left");
    
//    [self.view setHidden:YES]; // TODO some kind of animation
    
    if([_parentController respondsToSelector:@selector(next)])
        [_parentController performSelectorOnMainThread:@selector(next) withObject:nil waitUntilDone:YES];
}
@end
