//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

@protocol QTreeFilterController <NSObject>
// Hook for filtering the results
- (NSArray *) applyFilterToArrayOfInsertableObjects:(NSArray *)sourceArray;

@end
