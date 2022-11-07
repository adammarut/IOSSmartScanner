//
//  UIImage+Rotate.h
//  OpenCVApp
//
//  Created by Adam Marut on 14/10/2022.
//

#ifndef UIImage_Rotate_h
#define UIImage_Rotate_h

#import <UIKit/UIKit.h>

@interface UIImage (Rotate)

//faster, alters the exif flag but doesn't change the pixel data
- (UIImage*)rotateExifToOrientation:(UIImageOrientation)orientation;


//slower, rotates the actual pixel matrix
- (UIImage*)rotateBitmapToOrientation:(UIImageOrientation)orientation;

- (UIImage*)rotateToImageOrientation;

@end
#endif /* UIImage_Rotate_h */
