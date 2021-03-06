//
//  FlickrAPIClient.h
//  FlickrWorld
//
//  Created by Nadia Yudina on 3/19/14.
//  Copyright (c) 2014 Nadia Yudina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo+Methods.h"

@interface FlickrAPIClient : NSObject

extern NSString * const BASE_URL;
extern NSString * const PARAMS;


- (void)fetchInterestingPhotosWithCompletion: (void(^)(NSArray *))completionBlock Failure: (void(^)(NSInteger))failureBlock;
- (void)fetchThumbnailsForPhoto: (Photo *)photo Completion: (void(^)(NSData *))completionBlock ;



@end
