//
//  FGalleryMediaObject.h
//  FGallery
//
//  Created by Yuichi Fujiki on 10/6/11.
//  Copyright (c) 2011 Yuichi Fujiki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGalleryViewController.h"

@interface MediaObject : NSObject {
    NSString * _caption;
    NSString * _url;
    NSString * _thumbnailUrl;
    FGalleryMediaType _type;
}

@property (nonatomic, strong) NSString * caption;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * thumbnailUrl;
@property (nonatomic, assign) FGalleryMediaType type;

- (id) initWithCaption:(NSString *)caption url:(NSString *)url thumbnailUrl:(NSString*)thumbnailUrl type:(FGalleryMediaType)type;
@end
