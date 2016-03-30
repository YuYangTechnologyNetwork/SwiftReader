//
//  Build.h
//  NovelReader
//
//  Created by kangyonggen on 3/30/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

#ifndef Build_h
#define Build_h

#ifdef DEBUG
# define DLog(fmt, ...) NSLog((@"\n%s#%s->line:%d\n"fmt"\n\n"), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define DLog(...);
#endif

#endif /* Build_h */
