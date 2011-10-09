// Copyright © 2010 Factory Design Labs
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of 
// this software and associated documentation files (the ‘Software’), to deal in 
// the Software without restriction, including without limitation the rights to use, 
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
// the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
// A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 
//
//  RootViewController.m
//  FGallery
//
//  Created by Grant Davis on 1/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "MediaObject.h"

@implementation RootViewController


#pragma mark - View lifecycle

- (void)loadView {
	[super loadView];
    
	self.title = @"FGallery";
    localMediaObjects = [[NSArray alloc] initWithObjects:
        [[MediaObject alloc] initWithCaption:@"Lava" url:@"lava.jpeg" thumbnailUrl:@"lava.jpeg" type:FGalleryMediaTypeImage],
        [[MediaObject alloc] initWithCaption:@"Hawaii" url:@"hawaii.jpeg" thumbnailUrl:@"hawaii.jpeg" type:FGalleryMediaTypeImage],
        [[MediaObject alloc] initWithCaption:@"Dog Video" url:@"haku.mov" thumbnailUrl:@"haku.png" type:FGalleryMediaTypeVideo],                         
        [[MediaObject alloc] initWithCaption:@"Audi" url:@"audi.jpg" thumbnailUrl:@"audi.jpg" type:FGalleryMediaTypeImage],
    nil];
    
    networkMediaObjects = [[NSArray alloc] initWithObjects:
        [[MediaObject alloc] initWithCaption:@"Happy New Year!" url:@"http://farm6.static.flickr.com/5042/5323996646_9c11e1b2f6_b.jpg" thumbnailUrl:@"http://farm6.static.flickr.com/5042/5323996646_9c11e1b2f6_b.jpg" type:FGalleryMediaTypeImage], 
        [[MediaObject alloc] initWithCaption:@"Frosty Web" url:@"http://farm6.static.flickr.com/5007/5311573633_3cae940638.jpg" thumbnailUrl:@"http://farm6.static.flickr.com/5007/5311573633_3cae940638.jpg" type:FGalleryMediaTypeImage],        
        [[MediaObject alloc] initWithCaption:@"Dog video" url:@"https://s3.amazonaws.com/houston_city_dev/video/h264-original/1/haku.mp4" thumbnailUrl:@"https://s3.amazonaws.com/houston_city_dev/video/h264-original/1/thumb/frame_0000.png" type:FGalleryMediaTypeVideo],                           
    nil];
}

#pragma mark - Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	// Configure the cell.
	if( indexPath.row == 0 ) {
		cell.textLabel.text = @"Local Images";
	}
    else if( indexPath.row == 1 ) {
		cell.textLabel.text = @"Network Images";
	}
	else if( indexPath.row == 2 ) {
		cell.textLabel.text = @"Custom Controls";
	}

    return cell;
}


#pragma mark - FGalleryViewControllerDelegate Methods


- (int)numberOfMediasForGallery:(FGalleryViewController *)gallery
{
    int num = 0;
    if( gallery == localGallery ) {
        num = [localMediaObjects count];
    }
    else if( gallery == networkGallery ) {
        num = [networkMediaObjects count];
    }
	return num;
}


- (FGalleryMediaSourceType)mediaGallery:(FGalleryViewController *)gallery sourceTypeForMediaAtIndex:(NSUInteger)index
{
	if( gallery == localGallery ) {
		return FGalleryMediaSourceTypeLocal;
	}
	else return FGalleryMediaSourceTypeNetwork;
}

- (FGalleryMediaType)mediaGallery:(FGalleryViewController *)gallery mediaTypeForMediaAtIndex:(NSUInteger)index
{
    FGalleryMediaType type;
	if( gallery == localGallery ) 
    {
        type = [(MediaObject *)[localMediaObjects objectAtIndex:index] type];
	}
	else
    {
        type = [(MediaObject *)[networkMediaObjects objectAtIndex:index] type];        
    }
    return type;
}


- (NSString*)mediaGallery:(FGalleryViewController *)gallery captionForMediaAtIndex:(NSUInteger)index
{
    NSString *caption;
    if( gallery == localGallery ) {
        caption = [(MediaObject *)[localMediaObjects objectAtIndex:index] caption];
    }
    else if( gallery == networkGallery ) {
        caption = [(MediaObject *)[networkMediaObjects objectAtIndex:index] caption];
    }
	return caption;
}


- (NSString*)mediaGallery:(FGalleryViewController*)gallery filePathForMediaSize:(FGalleryMediaSize)size atIndex:(NSUInteger)index {
    switch (size) {
        case FGalleryMediaSizeThumbnail:
            return [(MediaObject *)[localMediaObjects objectAtIndex:index] thumbnailUrl];
            break;            
        default:
            return [(MediaObject *)[localMediaObjects objectAtIndex:index] url];
            break;
    }

}

- (NSString*)mediaGallery:(FGalleryViewController *)gallery urlForMediaSize:(FGalleryMediaSize)size atIndex:(NSUInteger)index {
    switch (size) {
        case FGalleryMediaSizeThumbnail:
            return [(MediaObject *)[networkMediaObjects objectAtIndex:index] thumbnailUrl];
            break;            
        default:
            return [(MediaObject *)[networkMediaObjects objectAtIndex:index] url];
            break;
    }
}

- (void)handleTrashButtonTouch:(id)sender {
    // here we could remove images from our local array storage and tell the gallery to remove that image
    // ex:
    //[localGallery removeImageAtIndex:[localGallery currentIndex]];
}


- (void)handleEditCaptionButtonTouch:(id)sender {
    // here we could implement some code to change the caption for a stored image
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    imageCount = 5;
    
	if( indexPath.row == 0 ) {
		localGallery = [[FGalleryViewController alloc] initWithMediaSource:self];
        [self.navigationController pushViewController:localGallery animated:YES];
	}
    else if( indexPath.row == 1 ) {
		networkGallery = [[FGalleryViewController alloc] initWithMediaSource:self];
        [self.navigationController pushViewController:networkGallery animated:YES];
    }
	else if( indexPath.row == 2 ) {
		UIImage *trashIcon = [UIImage imageNamed:@"photo-gallery-trashcan.png"];
		UIImage *captionIcon = [UIImage imageNamed:@"photo-gallery-edit-caption.png"];
		UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithImage:trashIcon style:UIBarButtonItemStylePlain target:self action:@selector(handleTrashButtonTouch:)];
		UIBarButtonItem *editCaptionButton = [[UIBarButtonItem alloc] initWithImage:captionIcon style:UIBarButtonItemStylePlain target:self action:@selector(handleEditCaptionButtonTouch:)];
		NSArray *barItems = [NSArray arrayWithObjects:editCaptionButton, trashButton, nil];
		
		localGallery = [[FGalleryViewController alloc] initWithMediaSource:self barItems:barItems];
        [self.navigationController pushViewController:localGallery animated:YES];
	}
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}




@end

