#import <Foundation/Foundation.h>

#define DATA_SIZE 256

@interface BrlList : NSObject {
	id Start;	// リンクリスト先頭へのポインタ
	id Next;	// 次のリストへのポインタ
	id Before;	// 前のリストへのポインタ
	unsigned char Attr;	// リストの属性
	unsigned char UserInfo;	// ユーザー情報(データの先頭１バイトが複写)
	unsigned char Data[DATA_SIZE];	// データ
}
- (void)SetAttr:(unsigned char)Dat;
- (unsigned char)GetAttr;
- (void)SetUserInfo:(unsigned char)Dat;
- (unsigned char)GetUserInfo;
- (void)SetData:(unsigned char *) Dat;
- (unsigned char *)GetData;
- (void)SetStart:(id)Dat;
- (id)GetStart;
- (void)SetNext:(id)Dat;
- (id)GetNext;
- (void)SetBefore:(id)Dat;
- (id)GetBefore;
@end
