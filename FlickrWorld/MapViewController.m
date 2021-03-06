//
//  MapViewController.m
//  FlickrWorld
//
//  Created by Nadia Yudina on 3/21/14.
//  Copyright (c) 2014 Nadia Yudina. All rights reserved.
//

#import "MapViewController.h"
#import "FlickrDataStore.h"
#import "FlickrAnnotation.h"
#import "ImageScrollViewController.h"
#import <FontAwesomeKit.h>
#import "UIColor+Pallete.h"
#import "FlickrAPIClient.h"
#import <AFNetworking.h>
#import "AppDelegate.h"
#import "JPSThumbnailAnnotation.h"
#import "Reachability.h"




@interface MapViewController ()

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIView *blackVIew;

@property (strong, nonatomic) FlickrDataStore *dataStore;
@property (strong, nonatomic) Photo *photo;

@property (strong, nonatomic) NSArray *selectedAnnotations;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSMutableArray *annotatedPlaces;//prevent from adding one annotation to map more than once
@property (strong, nonatomic) IBOutlet UIButton *refreshButton;

@property (strong, nonatomic) IBOutlet UIButton *recentButton;

@property (strong, nonatomic) AFHTTPSessionManager *manager;

@end



@implementation MapViewController

- (IBAction)refreshButtonPressed:(id)sender {
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [self.dataStore cleanCoreData];
    
    [self.refreshButton setEnabled:NO];
    
    [self.dataStore fetchDataWithCompletion:^(BOOL isLast) {
        
        [self fetchAndShowPlaces];
        
        if (isLast) {
            
            [self.refreshButton setEnabled:YES];
        }
        
    } Failure:^(NSInteger errorCode) {
        
        [self handleError:errorCode];
    }];
}


- (void)createImageForRefreshButtonWithColor: (UIColor *)color
{
    FAKIonIcons *refreshIcon = [FAKIonIcons ios7ReloadIconWithSize:50];
    
    UIImage *refreshImage = [refreshIcon imageWithSize:CGSizeMake(50, 50)];
    [self.refreshButton setTintColor:color];
    [self.refreshButton setImage:refreshImage forState:UIControlStateNormal];
    [self.view bringSubviewToFront:self.refreshButton];
}


- (void)createImageForRecentButtonWithColor: (UIColor *)color
{
    FAKIonIcons *refreshIcon = [FAKIonIcons ios7ClockOutlineIconWithSize:50];
    
    UIImage *refreshImage = [refreshIcon imageWithSize:CGSizeMake(50, 50)];
    [self.recentButton setTintColor:color];
    [self.recentButton setImage:refreshImage forState:UIControlStateNormal];
    [self.view bringSubviewToFront:self.recentButton];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self changeColorForSelectedAnnotation];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) {
        
        UIAlertView *noConnectionAlert = [[UIAlertView alloc]initWithTitle:@"No internet connection"
                                                                   message:@"Press Home"
                                                                  delegate:self
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:nil, nil];
        
        [noConnectionAlert show];
        
    } else {
        
        self.manager = [AFHTTPSessionManager manager];
        
        self.dataStore = [FlickrDataStore sharedDataStore];
        
        [self.dataStore cleanCoreData];
        
        self.annotatedPlaces = [[NSMutableArray alloc]init];
        
        [self.view bringSubviewToFront:self.blackVIew];
        
        self.mapView.delegate = self;
        self.mapView.mapType = MKMapTypeStandard;
        
        [self.spinner startAnimating];
        
        [self createMapRegion];
        
        [self.refreshButton setEnabled:NO];
        
        [self.dataStore fetchDataWithCompletion:^(BOOL isLast) {
            
            [self fetchAndShowPlaces];
            
            if (isLast) {
                
                [self.refreshButton setEnabled:YES];
                
                [self.dataStore saveContext];
            }
        } Failure:^(NSInteger errorCode) {
            
            [self handleError:errorCode];
            
            NSLog(@"%d", errorCode);
        }];
        
    }
}


- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    [self.spinner stopAnimating];
    
    [self createImageForRefreshButtonWithColor:[UIColor blueOpaque]];
    
    [self createImageForRecentButtonWithColor:[UIColor blueOpaque]];
    
    [self.view sendSubviewToBack:self.blackVIew];
}


- (void)createMapRegion
{
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    
    [self.mapView setRegion:region animated:YES];
}



- (void)fetchAndShowPlaces
{
    //fetching from Core Data to populate the map view with annotations
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
    NSArray *photos = [self.dataStore.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    for (Photo *photo in photos) {
            
        if (photo.largeImageLink) { //if there is broken link
            
            [self.annotatedPlaces addObject:photo];
            
            CLLocationCoordinate2D placeCoordinate;
            placeCoordinate.latitude = [photo.latitude floatValue];
            placeCoordinate.longitude = [photo.longitude floatValue];
            
            NSString *annotationTitle = [self createAnnotationTitle:photo];
            
            UIImage *buttonImage = [UIImage imageWithData:photo.thumbnail];
            
            FlickrAnnotation *annotation = [[FlickrAnnotation alloc] initWithWithTitle:annotationTitle
                                                                              Location:placeCoordinate
                                                                                 Image:buttonImage
                                                                                 Photo:photo];

            [self.mapView addAnnotation:annotation];
            
        }
    }
}



#pragma mark - Change Annotation Methods

- (NSString *)createAnnotationTitle: (Photo *)photo
{
    return photo.title;
}


- (void)changeColorForSelectedAnnotation
{
    UIColor *circleColor = [UIColor blueTransparent];
    
    FAKFontAwesome *circle = [FAKFontAwesome circleIconWithSize:40];
    [circle addAttribute:NSForegroundColorAttributeName value:circleColor];
    UIImage *circleImage = [circle imageWithSize:CGSizeMake(40, 40)];
    
    for (FlickrAnnotation *selectedAnotation in self.dataStore.selectedAnnotations) {
        
        MKAnnotationView *selectedAnnotationView = [self.mapView viewForAnnotation:selectedAnotation];

        selectedAnnotationView.image = circleImage;
    }
}

#pragma mark - MapView delegate methods

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[FlickrAnnotation class]]) {
        
        FlickrAnnotation *myLocation = (FlickrAnnotation *)annotation;
        
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"FlickrAnnotation"];

        annotationView = nil;
        
        annotationView = myLocation.annotationView;
        
        return annotationView;
        
    } else {
        
        return nil;
    }
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    
    FlickrAnnotation *annotation = view.annotation;

    [self.dataStore.selectedAnnotations addObject:annotation];
    
    //[self changeColorForSelectedAnnotation];
    
    [self.mapView deselectAnnotation:annotation animated:YES];

    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    ImageScrollViewController *imageVC = (ImageScrollViewController *)[storyBoard instantiateViewControllerWithIdentifier:@"image"];
    
    imageVC.photo = annotation.photo;
    
    [self.navigationController presentViewController:imageVC animated:YES completion:nil];

}


#pragma mark - Error handling 

- (void)handleError: (NSInteger) errorCode
{
    if (errorCode == 400) {
        
        UIAlertView *alertConnect = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"Please check your connection" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertConnect show];
    
    } else if (errorCode == 404) {
    
        UIAlertView *alertBad = [[UIAlertView alloc] initWithTitle:@"Server error" message:@"Please try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertBad show];
    }

}


@end
