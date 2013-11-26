//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import <MapKit/MapKit.h>

BOOL MKCoordinateRegionIntersectsRegion(MKCoordinateRegion region1, MKCoordinateRegion region2);
BOOL MKCoordinateRegionContainsCoordinate(MKCoordinateRegion region, CLLocationCoordinate2D coordinate);

inline CLLocationDistance CLMetersBetweenCoordinates(CLLocationCoordinate2D c1, CLLocationCoordinate2D c2);

