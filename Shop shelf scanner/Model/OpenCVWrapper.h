//
//  OpenCVWrapper.h
//  OpenCVApp
//
//  Created by Adam Marut on 13/10/2022.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImage+Rotate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;
+ (UIImage *) toGray:(UIImage *)source;
+ (UIImage *)stitchPhotos:(UIImage *) source1 photo2: (UIImage *) source2 panoramicWarp:(BOOL) isPanoramic;;
+ (UIImage *)cropStitchedPhoto:(UIImage *) source;
+ (UIImage *)stitchPhotos:(NSArray *) photos panoramicWarp:(BOOL) isPanoramic;
@end

NS_ASSUME_NONNULL_END
