//
//  ShareUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/1/16.
//
//

#import "ShareUtils.h"


#define k_share_link_middle_part_url_before_version_8 @"public.php?service=files&t="
#define k_share_link_middle_part_url_after_version_8 @"index.php/s/"

#define k_server_version_with_new_shared_schema 8


@implementation ShareUtils

+ (NSMutableArray *) manageTheDuplicatedUsers: (NSMutableArray*) items{
    
    for (OCShareUser *userOrGroup in items) {
        NSMutableArray *restOfItems = [NSMutableArray arrayWithArray:items];
        [restOfItems removeObjectIdenticalTo:userOrGroup];
        
        if(restOfItems.count == 0)
            userOrGroup.isDisplayNameDuplicated = NO;
        
        else{
            for (OCShareUser *tempItem in restOfItems) {
                if ([userOrGroup.displayName isEqualToString:tempItem.displayName] && ((!userOrGroup.server && !tempItem.server) || ([userOrGroup.server isEqualToString:tempItem.server]))){
                    userOrGroup.isDisplayNameDuplicated = YES;
                    break;
                }
            }
        }
    }
    
    return items;
}


+ (NSURL *) getNormalizedURLOfShareLink:(OCSharedDto *)sharedLink {
    
    
    NSString *urlSharedLink = sharedLink.url ? sharedLink.url : sharedLink.token;
    
    NSString *url = nil;
    // From ownCloud server 8.2 the url field is always set for public shares
    if ([urlSharedLink hasPrefix:@"http://"] || [urlSharedLink hasPrefix:@"https://"])
    {
        url = urlSharedLink;
    }else{
        //Token
        NSString *firstNumber = [[AppDelegate sharedOCCommunication].getCurrentServerVersion substringToIndex:1];
        
        if (firstNumber.integerValue >= k_server_version_with_new_shared_schema) {
            // From ownCloud server version 8 on, a different share link scheme is used.
            url = [NSString stringWithFormat:@"%@%@%@", APP_DELEGATE.activeUser.url, k_share_link_middle_part_url_after_version_8, sharedLink];
        }else{
            url = [NSString stringWithFormat:@"%@%@%@", APP_DELEGATE.activeUser.url, k_share_link_middle_part_url_before_version_8, sharedLink];
        }
    }
    
    return  [NSURL URLWithString:url];
}


@end
