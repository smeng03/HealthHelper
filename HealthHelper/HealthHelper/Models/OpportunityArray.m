//
//  OpportunityArray.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/28/21.
//

#import <Foundation/Foundation.h>
#import "OpportunityArray.h"

@interface OpportunityArray() <NSDiscardableContent>

@end

@implementation OpportunityArray

//@synthesize opportunities;

- (void)setOpportunityArray:(NSMutableArray *)opportunityArray {
    self.opportunities = opportunityArray;
}

- (BOOL)beginContentAccess {
    return TRUE;
}

- (void)discardContentIfPossible {
}

- (void)endContentAccess {
}

- (BOOL)isContentDiscarded {
    return FALSE;
}

@end
