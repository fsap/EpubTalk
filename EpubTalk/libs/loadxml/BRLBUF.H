#import <Foundation/Foundation.h>
#import "file.h"

#define BUF_LIST_HEAD	'S'
#define BUF_LIST_END	'E'
#define BUF_DEL_LIST_HEAD	's'
#define BUF_DEL_LIST_END	'E'
#define BUF_LIST_DATA	'D'
#define RBUF_SIZE 1024
#define CR_MARK	0x0d
#define PR_MARK	0x0c

@interface BrlBuffer : NSObject {
	id m_lpList;
	id m_lpDelList;
	id m_tostr;
	NSString* Word;
	BRLDOC_DAT *Data;
	BRLDOC_LINE_ATTR LineAttr;
}
- (void)Setinit;
- (void)Ins:(unsigned char *)Dat;
- (BOOL)IsBuffer;
- (BOOL)Del;
- (void)Remove;
- (char *)GetDat;
- (BOOL)NextLine;
- (void)Top;
- (void)End;
- (BOOL)SetLine:(unsigned short)Line;
- (unsigned short)IsCurLine;
@end
