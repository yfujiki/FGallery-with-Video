//
//  FGalleryMediaObject.m
//  FGallery
//
//  Created by Yuichi Fujiki on 10/6/11.
//  Copyright (c) 2011 Yuichi Fujiki. All rights reserved.
//

#import "MediaObject.h"

@implementation MediaObject

@synthesize caption = _caption, url = _url, thumbnailUrl = _thumbnailUrl, type = _type;

- (id) initWithCaption:(NSString *)caption url:(NSString *)url thumbnailUrl:(NSString*)thumbnailUrl type:(FGalleryMediaType)type
{
    if(self = [super init])
    {
        _caption = caption;
        _url = url;
        _thumbnailUrl = thumbnailUrl;
        _type = type;
    }        
    return self;
}
@end
