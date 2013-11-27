//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import "QCluster.h"

@implementation QCluster

static CLLocationDegrees DegreesMetric(CLLocationCoordinate2D c1, CLLocationCoordinate2D c2)
{
    return sqrt(pow(c1.latitude - c2.latitude, 2) + pow(c1.longitude - c2.longitude, 2));
}

static CLLocationCoordinate2D MeanCoordinate(NSArray* insertableObjects)
{
    CLLocationDegrees meanLatitude = 0;
    CLLocationDegrees meanLongitude = 0;
    for( id<QTreeInsertable> object in insertableObjects ) {
        meanLongitude += object.coordinate.longitude;
        meanLatitude += object.coordinate.latitude;
    }
    meanLatitude /= insertableObjects.count;
    meanLongitude /= insertableObjects.count;
    return CLLocationCoordinate2DMake(meanLatitude, meanLongitude);
}

static CLLocationDegrees CircumscribedDegreesRadius(NSArray* insertableObjects, CLLocationCoordinate2D center)
{
    CLLocationDegrees radius = 0;
    for( id<QTreeInsertable> object in insertableObjects ) {
        radius = MAX(radius, DegreesMetric(object.coordinate, center));
    }
    return radius;
}

- (id) initWithChildren:(NSArray *)allChildren {
    if ((self = [super init])) {
        CLLocationCoordinate2D meanCenter = MeanCoordinate(allChildren);
        _coordinate = meanCenter;
        _objectsCount = allChildren.count;
        _radius = CircumscribedDegreesRadius(allChildren, meanCenter);
    }
    return self;
}

@end
