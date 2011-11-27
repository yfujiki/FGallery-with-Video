//
//  FGalleryVideoView.h
//  FirstAVPlayer
//
//  Created by Yuichi Fujiki on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVFoundation/AVPlayer.h"

@protocol FGalleryVideoViewDelegate;

@interface FGalleryVideoView : UIView {
    BOOL _isPlaying;    
}

@property (nonatomic,unsafe_unretained) NSObject <FGalleryVideoViewDelegate> *videoDelegate;
@property (nonatomic, retain) UIButton * playbackButton;
@property (nonatomic, retain) AVPlayer * player;

- (void)setVideoFillMode:(NSString *)fillMode;

- (void)togglePlayback:(id)sender;
- (void)play;
- (void)pause;

- (void)toggleControls;
- (void)showControls:(BOOL)animated;
- (void)hideControls:(BOOL)animated;
- (void)hideSelf:(id)sender;
- (void)showSelf:(id)sender;

- (void)playerItemDidReachEnd:(NSNotification *)notification;

@end

@protocol FGalleryVideoViewDelegate

// indicates single touch and allows controller repsond and go toggle fullscreen
- (void)didTapVideoView:(FGalleryVideoView*)videoView;

@end
