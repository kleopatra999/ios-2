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

+ (BOOL) isPasswordEnforcedCapabilityEnabled {
    
    BOOL output;
    
    if ((APP_DELEGATE.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingPasswordEnforcedEnabled) ) {
        
        output = YES;
        
    } else {
        
        output = NO;
    }
    
    return output;
}

+ (NSString *) getPasswordEncodingWithPassword:(NSString *)password {
    
    NSString *encodePassword = [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];
    
    return encodePassword;
    
}



//+ (void) createNewShareLink:(OCSharedDto *)shareLink ofFile:(FileDto *)file {
//    
////    [self initLoading];
//    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
//
//    
//    //Set the right credentials
//    if (k_is_sso_active) {
//        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
//    } else if (k_is_oauth_active) {
//        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
//    } else {
//        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:APP_DELEGATE.activeUser.password];
//    }
//    
//    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
//    
////    __block OCSharedDto *blockShareDto = _shareDto;
//    
//    
//    //Checking the Shared files and folders
//    [[AppDelegate sharedOCCommunication] shareFileOrFolderByServer:[UtilsUrls getFullRemoteServerPath:app.activeUser] andFileOrFolderPath:file.filePath onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *shareLink, NSString *redirectedServer) {
//        
//        BOOL isSamlCredentialsError=NO;
//        
//        //Check the login error in shibboleth
//        if (k_is_sso_active) {
//            //Check if there are fragmens of saml in url, in this case there are a credential error
//            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
//            if (isSamlCredentialsError) {
////                [self endLoading];
////                
////                [self errorLogin];
//            }
//        }
//        if (!isSamlCredentialsError) {
//            
//            //Ok we have the token but we also need all the information of the file in order to populate the database
//            [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
//            
////            [self endLoading];
//            
//            //Present
//            //  [self presentShareActionSheetForToken:shareLink withPassword:false];
//        }
//        
//    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
//        
////        [self endLoading];
//        
//        BOOL isSamlCredentialsError=NO;
//        
//        //Check the login error in shibboleth
//        if (k_is_sso_active) {
//            //Check if there are fragmens of saml in url, in this case there are a credential error
//            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
//            if (isSamlCredentialsError) {
//                
////                [self errorLogin];
//            }
//        }
//        if (!isSamlCredentialsError) {
//            
//            DLog(@"error.code: %ld", (long)error.code);
//            DLog(@"server error: %ld", (long)response.statusCode);
//            
//            if (error.code == kOCErrorServerForbidden && [self isPasswordEnforcedCapabilityEnabled]) {
//                
//                //Share whith password maybe enabled, ask for password and try to do the request again with it
//                // [self showAlertEnterPassword]; //TODO: ask password if needed
//                
//            } else {
////                [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
//            }
//            
//            if (error.code != kOCErrorServerForbidden) {
//                
////                if([self.delegate respondsToSelector:@selector(finishShareWithStatus:andWithOptions:)]) {
////                    [self.delegate finishShareWithStatus:false andWithOptions:nil];
////                }
//            }
//        }
//        
//    }];
//
//}



@end
