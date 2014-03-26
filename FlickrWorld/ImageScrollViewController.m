//
//  ImageScrollViewController.m
//  ImageScroll
//
//  Created by Evgenii Neumerzhitckii on 19/05/13.
//  Copyright (c) 2013 Evgenii Neumerzhitckii. All rights reserved.
//

#import "ImageScrollViewController.h"
#import "UIImageView+AFNetworking.h"
#import <FontAwesomeKit.h>
#import <MPColorTools.h>
#import "FlickrDataStore.h"


@interface ImageScrollViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *infoView;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) IBOutlet UIButton *infoButton;

@property (strong, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) FlickrDataStore *dataStore;

@end

@implementation ImageScrollViewController

- (IBAction)infoButtonPressed:(id)sender
{
    if ([self.view.subviews lastObject] == self.infoView) {
        [self.view sendSubviewToBack:self.infoView];
    } else {
        [self.view bringSubviewToFront:self.infoView];
        [self.infoLabel sizeToFit];
        [self putTextToLabel];
    }
}

- (void)putTextToLabel
{
    self.infoLabel.text = [NSString stringWithFormat:@"Title: %@\nPhotographer: %@", self.photo.title, self.photo.ownerId];
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.dataStore saveContext];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    UIColor *circleColor = [UIColor colorWithRed:255 green:0 blue:127 alpha:1.0];
    
    FAKFontAwesome *infoIcon = [FAKFontAwesome infoCircleIconWithSize:30];
    UIImage *infoImage = [infoIcon imageWithSize:CGSizeMake(30, 30)];
    [self.infoButton setTintColor:circleColor];
    [self.infoButton setImage:infoImage forState:UIControlStateNormal];
    [self.view bringSubviewToFront:self.infoButton];
    

    FAKFontAwesome *globe = [FAKFontAwesome globeIconWithSize:30];
    UIImage *globeImage = [globe imageWithSize:CGSizeMake(30, 30)];
    [self.backButton setTintColor:circleColor];
    [self.backButton setImage:globeImage forState:UIControlStateNormal];
    [self.view bringSubviewToFront:self.backButton];
    
    [self.view bringSubviewToFront:self.spinner];
    
}


- (void) viewWillAppear:(BOOL)animated

{
    
    [super viewWillAppear:animated];
    
    self.dataStore = [FlickrDataStore sharedDataStore];
    
    self.scrollView.delegate = self;
    
    [self updateZoom];
    
    if (!self.imageView.image) {
        
        [self.spinner startAnimating];
        
        NSURL *url = [NSURL URLWithString:self.photo.largeImageLink];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        
        [self.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            self.imageView.image = image;
            
            [self.spinner stopAnimating];
            
            [self updateZoom];

            self.photo.lastViewed = [NSDate date];
            
            [self.dataStore saveContext]; 
   
        } failure:nil];
        
    }

}

// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    [self updateZoom];
    
    // A hack needed for small images to animate properly on orientation change
    if (self.scrollView.zoomScale == 1) self.scrollView.zoomScale = 1.0001;
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self updateConstraints];
}

- (void) updateConstraints {
    
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;
    
    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    // center image if it is smaller than screen
    float hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    if (hPadding < 0) hPadding = 0;
    
    float vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    if (vPadding < 0) vPadding = 0;
    
    self.constraintLeft.constant = hPadding;
    self.constraintRight.constant = hPadding;
    
    self.constraintTop.constant = vPadding;
    self.constraintBottom.constant = vPadding;
}

// Zoom to show as much image as possible unless image is smaller than screen
- (void) updateZoom
{
    float minZoom = MIN(self.view.bounds.size.width / self.imageView.image.size.width,
                        self.view.bounds.size.height / self.imageView.image.size.height);
    
    if (minZoom > 1) minZoom = 1;
    
    self.scrollView.minimumZoomScale = minZoom;
    
    
    self.scrollView.zoomScale = minZoom;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}




@end
