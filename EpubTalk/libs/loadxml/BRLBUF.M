#import <Foundation/Foundation.h>    
#import "brlbuf.h"
#import "list.h"
@implementation BrlBuffer 
- (void)Setinit {
	m_lpList = [[BrlList alloc] init];
	m_lpList = [m_lpList autorelease];
	id lpTmpList = [[BrlList alloc] init];
	lpTmpList = [lpTmpList autorelease];
	m_lpDelList = [[BrlList alloc] init];
	m_lpDelList = [m_lpDelList autorelease];
	id lpTmpDelList = [[BrlList alloc] init];
	lpTmpDelList = [lpTmpDelList autorelease];
	// リストのデータを編集し、接続します
	[m_lpList SetAttr:BUF_LIST_HEAD];
	[m_lpList SetStart:m_lpList];
	[m_lpList SetNext:lpTmpList];
	[m_lpList SetBefore:lpTmpList];
	[lpTmpList SetAttr:BUF_LIST_END];
	[lpTmpList SetStart:m_lpList];
	[lpTmpList SetNext:m_lpList];
	[lpTmpList SetBefore:m_lpList];
	// 削除リストの構築
	[m_lpDelList SetAttr:BUF_DEL_LIST_HEAD];
	[m_lpDelList SetStart:m_lpDelList];
	[m_lpDelList SetNext:lpTmpDelList];
	[m_lpDelList SetBefore:lpTmpDelList];
	[lpTmpDelList SetAttr:BUF_DEL_LIST_END];
	[lpTmpDelList SetStart:m_lpDelList];
	[lpTmpDelList SetNext:m_lpDelList];
	[lpTmpDelList SetBefore:m_lpDelList];
/*
FILE *fp = fopen("log.txt", "a");
fprintf(fp, "setinit\n");
fclose(fp);
*/
}

- (unsigned char)IsAttr {
	return [m_lpList GetAttr];
}

- (BOOL)IsBuffer {
	id TmpList = [m_lpList GetStart];
	if ([[TmpList GetNext] GetAttr] == BUF_LIST_END) {
		return FALSE;
	}
	return TRUE;
}

- (BOOL)Del {
	if (![self IsBuffer]) {
		return FALSE;
	}
	id TmpList = m_lpList;
	m_lpList = [m_lpList GetBefore];
	[[TmpList GetNext] SetBefore:m_lpList];
	[m_lpList SetNext:[TmpList GetNext]];
	id DelTmpList = [m_lpDelList GetStart];
	id DelTmpNextList = [[m_lpDelList GetStart] GetNext];
	[TmpList SetStart:[DelTmpList GetStart]];
	[TmpList SetNext:[DelTmpList GetNext]];
	[TmpList SetBefore:[DelTmpList GetStart]];
	[DelTmpList SetNext:TmpList];
	[DelTmpNextList SetBefore:TmpList];
	return TRUE;
}

- (void)Remove {
	if (![self IsBuffer]) {
		return;
	}
	[self End];
	while ([self IsBuffer]) {
		[self Del];
		if ([m_lpList GetAttr] == BUF_LIST_HEAD) {
			break;
		}
	}
}

- (void)Ins:(unsigned char *)Dat {
	id TmpList;
	m_lpDelList = [m_lpDelList GetStart];
	if ([[m_lpDelList GetNext] GetAttr] != BUF_LIST_END) {	// ストックオブジェクトから拾う
		TmpList = [m_lpDelList GetNext];
		[[TmpList GetNext] SetBefore:m_lpDelList];
		[m_lpDelList SetNext:[TmpList GetNext]];
	} else {	// ストックが存在しないので新しいオブジェクトを作成
		TmpList = [[BrlList alloc] init];
		TmpList = [TmpList autorelease];
		[TmpList SetAttr:BUF_LIST_DATA];
	}
	[TmpList SetStart:[m_lpList GetStart]];
	[TmpList SetNext:[m_lpList GetNext]];
	[TmpList SetBefore:m_lpList];
	[[m_lpList GetNext] SetBefore:TmpList];
	[m_lpList SetNext:TmpList];
	m_lpList = TmpList;
	[m_lpList SetData:Dat];
	[m_lpList SetUserInfo:*Dat];
}

- (char *)GetDat {
	char* str = (char *)[m_lpList GetData];
//	Word = [NSString stringWithCString: str encoding:NSUTF8StringEncoding];
	return str;
}

- (BOOL)NextLine {
	if ([[m_lpList GetNext] GetAttr] == BUF_LIST_END)
		return FALSE;
	m_lpList = [m_lpList GetNext];
	return TRUE;
}


- (void)Top {
	m_lpList = [[m_lpList GetStart] GetNext];
}

- (void)End {
	m_lpList = [[[m_lpList GetStart] GetBefore] GetBefore];
}

- (unsigned short)IsCurLine {
	unsigned short Line = 1;
	id Temp = m_lpList;
	[self Top];
	while (1) {
		if (Temp == m_lpList) {
			return Line;
		}
		if (![self NextLine]) {
			m_lpList = Temp;
			return 0;
		}
		Line++;
	}
	m_lpList = Temp;
	return 0;
}

- (BOOL)SetLine:(unsigned short)Line {
	unsigned short TempLine = 1;
	[self Top];
	if (!Line) {
		return TRUE;
	}
	while (1) {
		if (![self NextLine]) {
			[self Top];
			return 0;
		}
		TempLine++;
		if (TempLine == Line) {
			return TRUE;
		}
	}
	return 0;
}

@end
