#import <Foundation/Foundation.h>    
#import <stdio.h>	// for printf,fgets,puts
#import <ctype.h>	// for isspace, tolower
#import <string.h>	// for strcmp, strncpy, strlen
#import <stdlib.h>	// for atoi

#define BRLDOC_TAB_MAP_SIZE	10
#define BRLDOC_REV_MAP_SIZE	4
#define BRLDOC_SUBTTL_SIZE	30
#define SEP_NAME_SIZE	192
#define BES_FILE_ATTR	4	// ＩＢＭ－ＢＥＳ形式(*.bes)
#define BET_FILE_ATTR	5	// ＢＥ形式(*.bet)
#define BRLDOC_DAT_SIZE	256
#define BRLDOC_DAT_LENGTH 254
#define BRLDOC_MAX_DAT_INDEX 254
#define CR_MARK	0x0d
#define PR_MARK	0x0c

// 行属性
#define NOMAL_LINE_ATTR	0	// 通常
#define TOC_LINE_ATTR	1	// 見出し行
#define PR_LINE_ATTR	2	// 強制改ページ行
#define CL_STAB_ATTR	8	// 折れ線行
#define CL_LINE_ATTR	12	// 折れ線行
#define PAGE_LINE_ATTR	4	// ページ行

#define BR3_ED_MARK	0x13
#define BRLDOC_HEAD_SIZE	256

// ヘッダ領域
typedef struct {
	unsigned short AllLine;	// 総行
	unsigned short CurLine;	// 現在行
	unsigned char Move;	// 移動単位
	unsigned char VoiceGengo;	// 音声言語
	unsigned char VoiceItem;	// 音声種類
	unsigned char VoiceSpeed;	// 音声スピード
	unsigned char VoiceTone;	// 音声トーン
	unsigned char VoiceVolume;	// 音声ボリューム
	unsigned char fILLE1[6];	// 予備1
	char SearchWord[80];	// 検索語
	char YomikaeFileName[80];	// 読替ファイル名
	char fILLE2[80];	// 予備1
}TDV_HEAD;


// 文字のデータレイアウト
typedef union {
	char Code;
	char Dat;
}BRLDOC_DAT_CHAR;

// 行属性領域
typedef union {
	unsigned char Attr;
	struct BLINE_ATTR {
		unsigned char Page:1;
		unsigned char Mark:1;
		unsigned char Level:4;
		unsigned char Midashi:2;
	}Map;
}BRLDOC_LINE_ATTR;

// 補助行属性
typedef union {
	unsigned char Attr;
	struct BSUBLINE_ATTR {
		unsigned char Mark:1;
		unsigned char Index:1;
		unsigned char IndentCnt:6;
	}Map;
}BRLDOC_SUB_LINE_ATTR;

// データブロック領域
typedef union {
	char Line[BRLDOC_DAT_LENGTH];
	BRLDOC_DAT_CHAR Dat[BRLDOC_MAX_DAT_INDEX];
}BRLDOC_DATA_LINE;

// １行のデータレイアウト
typedef struct {
	BRLDOC_LINE_ATTR LineAttr;
	BRLDOC_SUB_LINE_ATTR SubAttr;
	BRLDOC_DATA_LINE Data;
}BRLDOC_DAT_BLOCK;
typedef union {
	char Data[BRLDOC_DAT_SIZE];
	BRLDOC_DAT_BLOCK Block;
}BRLDOC_DAT;

@interface File : NSObject {
	id m_EditBuffer;
	BRLDOC_DAT m_EditData;	// １行バッファ
}
- (void)DataSet:(id)Bufid;
- (int)LoadXmlFile:(const char *)filename ReadMode:(int)RMode;
- (int)LoadHtmlFile:(const char *)filename ReadMode:(int)RMode;
- (int)LoadTdvFile:(const char *)filename Head:(TDV_HEAD *)HeadInfo;
- (BOOL)SaveTdvFile:(const char *)filename Head:(TDV_HEAD*)HeadInfo;
- (int)SaveHead:(const char *)filename Head:(TDV_HEAD*)HeadInfo;
// 行属性を設定する関数
- (void)SetLineHead;
// 行内の最大文字取得関数
- (int)EditDataLen;
- (int)sSearch:(char *)Str1 Str2:(char *)Str2 Start:(int)Start;
- (int)IsKugiri:(char *)Str;
- (void)SetRuby:(char *)Str rStr:(char *)rStr;
- (void)SetBuf:(char *)Str;
- (void)SetCho:(unsigned char *)Str;
@end
