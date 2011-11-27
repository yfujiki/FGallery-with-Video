//
//  FGalleryVideoView.m
//  FirstAVPlayer
//
//  Created by Yuichi Fujiki on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FGalleryVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@implementation FGalleryVideoView

@synthesize videoDelegate = _videoDelegate;
@synthesize playbackButton = _playbackButton;

- (id) initWithFrame:(CGRect)frame 
{
    if(self = [super initWithFrame:frame])
    {
        _isPlaying = NO;
        
        self.backgroundColor = [UIColor blackColor];
                        
        self.playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playbackButton.frame = CGRectMake(self.frame.size.width / 2 - 32, self.frame.size.height / 2 - 32, 64, 64);
        [self.playbackButton setBackgroundImage:[UIImage imageNamed:@"PlayButton.png"] forState:UIControlStateNormal];
        [self.playbackButton addTarget:self action:@selector(togglePlayback:) forControlEvents:UIControlEventTouchUpInside];
                
        [self addSubview:self.playbackButton];     
    }
    return self;
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.playbackButton.frame = CGRectMake(frame.size.width / 2 - 32, frame.size.height / 2 - 32, 64, 64);    
}

+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
	return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player
{
	[(AVPlayerLayer*)[self layer] setPlayer:player];
}

/* Specifies how the video is displayed within a player layer’s bounds. 
 (AVLayerVideoGravityResizeAspect is default) */
- (void)setVideoFillMode:(NSString *)fillMode
{
	AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
	playerLayer.videoGravity = fillMode;
}

- (void)togglePlayback:(id)sender 
{
    if(!_isPlaying)
    {
        [self play];
    }
    else
    {
        [self pause];
    }
}

- (void) play
{
    [[((AVPlayerLayer *)[self layer]) player] play];
    
    [_playbackButton setBackgroundImage:[UIImage imageNamed:@"PauseButton.png"] forState:UIControlStateNormal];
    [self hideControls:YES];
    _isPlaying = YES;
    
    [self.videoDelegate didTapVideoView:self];    
}

- (void) pause
{
    [[((AVPlayerLayer *)[self layer]) player] pause];        
    [_playbackButton setBackgroundImage:[UIImage imageNamed:@"PlayButton.png"] forState:UIControlStateNormal];        
    _isPlaying = NO;    
}

- (void)toggleControls 
{
    if(_playbackButton.alpha == 0)
    {
        [self showControls:YES];
    }
    else
    {
        [self hideControls:YES];        
    }
}

- (void)showControls:(BOOL)animated {
    NSTimeInterval duration = (animated) ? 0.5 : 0;
    
    [UIView animateWithDuration:duration animations:^() {
        _playbackButton.alpha = 1;
    }];    
}

- (void)hideControls:(BOOL)animated {
    NSTimeInterval duration = (animated) ? 0.5 : 0;
    
    [UIView animateWithDuration:duration animations:^() {
        _playbackButton.alpha = 0;
    }];
}

- (void)hideSelf:(id)sender {
    NSTimeInterval duration = (sender) ? 0.5 : 0;
    
    [UIView animateWithDuration:duration animations:^ {
        self.alpha = 0;
    }];
}

- (void)showSelf:(id)sender {
    NSTimeInterval duration = (sender) ? 0.5 : 0;
    
    [UIView animateWithDuration:duration animations:^ {
        self.alpha = 1;
    }];
        
    [self hideControls:NO];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [[((AVPlayerLayer *)[self layer]) player] seekToTime:kCMTimeZero];
    [_playbackButton setBackgroundImage:[UIImage imageNamed:@"PlayButton.png"] forState:UIControlStateNormal];        
    _isPlaying = NO;
    
    [self showControls:YES];
}

#pragma mark - touch event
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if(touch.tapCount == 1)
    {
        [self toggleControls];
        
        // tell the controller
        if([self.videoDelegate respondsToSelector:@selector(didTapVideoView:)])
            [self.videoDelegate didTapVideoView:self];
    }
}
@end
