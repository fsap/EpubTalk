#import <Foundation/Foundation.h>    
#import "file.h"
#import "brlbuf.h"
#include <string.h>
@implementation File
- (void)DataSet:(id)Bufid {
	m_EditBuffer = Bufid;
}

- (int)LoadXmlFile:(const char *)filename ReadMode:(int)RMode {
//	FILE *fp;
	FILE *InFp;
	if((InFp = fopen(filename,"r")) == NULL) {
		return -1;
	}
/*
fp = fopen("log.txt", "a");
fprintf(fp, "%s\n",filename);
fclose(fp);
*/
	if (RMode) {
		[m_EditBuffer End];
	}
	else {
		[m_EditBuffer Remove];
	}
	char TmpDat[1024];
	char rStr[1024];
	int Start, End, End2;
	int Body = 0;
	int Midashi = 0;
	int Level = 0;
	int MidashiBak = 0;
	int Sent = 0;
	int reply = 0;
	int Ix = 0;
	memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
	while (1) {
		if (MidashiBak) {
			strcpy(TmpDat, "<h");
			TmpDat[2] = MidashiBak + 0x30;
			MidashiBak = 0;
			Ix = 3;
		}
		if((TmpDat[Ix] = fgetc(InFp)) == EOF) {
			break;
		}
		if (TmpDat[Ix] != 0x0a &&
		    [self sSearch:TmpDat Str2:"<br />" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"<br>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</p>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h1>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h2>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h3>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h4>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h5>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h6>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"<h1" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h2" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h2" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h3" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h4" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h5" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h6" Start:1] <= 0 &&
		    !(strlen(TmpDat) > 600 && !strncmp(TmpDat + strlen(TmpDat) - 3, "。", 3)) &&
		    !(strlen(TmpDat) > 600 && !strncmp(TmpDat + strlen(TmpDat) - 2, ". ", 2)) &&
		    !(strlen(TmpDat) > 600 && !strncmp(TmpDat + strlen(TmpDat) - 2, ", ", 2)) &&
		    !(strlen(TmpDat) > 600 && !strncmp(TmpDat + strlen(TmpDat) - 1, ">", 1)) &&
		    !(strlen(TmpDat) > 600 && !strncmp(TmpDat + strlen(TmpDat) - 3, "、", 3))) {
			Ix++;
			continue;
		}
		Ix = strlen(TmpDat)-1;
		while (Ix) {
			if (TmpDat[Ix] == '>') {
				TmpDat[Ix+1] = 0;
				break;
			}
			if (TmpDat[Ix] == 0x0a ||
			    TmpDat[Ix] == 0x0d ||
			    TmpDat[Ix] == 0x20) {
				Ix--;
				continue;
			}
			break;
		}
		if (TmpDat[strlen(TmpDat)-1] == 0x0a) {
			TmpDat[strlen(TmpDat) - 1] = 0;
			if (!strlen(TmpDat)) {
				Ix = 0;
				memset(TmpDat, 0x00, sizeof(TmpDat));
				continue;
			}
		}
		if (TmpDat[strlen(TmpDat)-1] == 0x0d) {
			TmpDat[strlen(TmpDat) - 1] = 0;
			if (!strlen(TmpDat)) {
				Ix = 0;
				memset(TmpDat, 0x00, sizeof(TmpDat));
				continue;
			}
		}
		if (!strncmp(TmpDat + strlen(TmpDat) - 3, "<h1", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h2", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h3", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h4", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h5", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h6", 3)) {
			MidashiBak = TmpDat[strlen(TmpDat) - 1] - 0x30;
			TmpDat[strlen(TmpDat) - 3] = 0;
		}
		Start = 0;
		while (1) {
			if (TmpDat[Start] != 0x20) {
				break;
			}
			Start++;
		}
		if (!TmpDat[Start]) {
			Ix = 0;
			memset(TmpDat, 0x00, sizeof(TmpDat));
			continue;
		}
		if ([self sSearch:TmpDat Str2:"<book" Start:0] != -1) {
			Body = 1;
		}
		if ([self sSearch:TmpDat Str2:"</book" Start:0] != -1) {
			Body = 0;
		}
		if (!Body) {
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		if ([self sSearch:TmpDat Str2:"<h1" Start:0] != -1) {
			Midashi = 1;
		}
		if ([self sSearch:TmpDat Str2:"<h2" Start:0] != -1) {
			Midashi = 2;
		}
		if ([self sSearch:TmpDat Str2:"<h3" Start:0] != -1) {
			Midashi = 3;
		}
		if ([self sSearch:TmpDat Str2:"<h4" Start:0] != -1) {
			Midashi = 4;
		}
		if ([self sSearch:TmpDat Str2:"<h5" Start:0] != -1) {
			Midashi = 5;
		}
		if ([self sSearch:TmpDat Str2:"<h6" Start:0] != -1) {
			Midashi = 6;
		}
		if ([self sSearch:TmpDat Str2:"<level1" Start:0] != -1) {
			Level = 1;
		}
		if ([self sSearch:TmpDat Str2:"<level2" Start:0] != -1) {
			Level = 2;
		}
		if ([self sSearch:TmpDat Str2:"<level3" Start:0] != -1) {
			Level = 4;
		}
		if ([self sSearch:TmpDat Str2:"<level4" Start:0] != -1) {
			Level = 8;
		}
		memset(rStr, 0x00, sizeof(rStr));
		Start = 0;
		while (1) {
			if (TmpDat[Start] != 0x20) {
				break;
			}
			Start++;
		}
		start6:
		if (!TmpDat[Start]) {
			if (strlen(rStr)) {
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
			}
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		else if ([self sSearch:TmpDat Str2:"<span class=\"ruby\">" Start:0] != -1) {
			m_EditData.Block.LineAttr.Map.Midashi = Midashi;
			m_EditData.Block.LineAttr.Map.Level = Level;
			memset(rStr, 0x00, sizeof(rStr));
			[self SetRuby:TmpDat rStr:rStr];
			[self SetBuf:rStr];
			Sent = 0;
			Midashi = 0;
			Level = 0;
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		else if (!strncmp(TmpDat + Start, "<pagenum " ,9)) {
			if (strlen(rStr)) {
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
			}
			Start = [self sSearch:TmpDat Str2:"\">" Start:Start+1];
			End = [self sSearch:TmpDat Str2:"</pagenum>" Start:Start+1];
			if (Start && End) {
				Start += 2;
				strncpy(m_EditData.Data+2, TmpDat + Start, End - Start);
				m_EditData.Block.LineAttr.Map.Page = 1;
				[m_EditBuffer Ins:m_EditData.Data];
				memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}
		}
		if (TmpDat[Start] == '<') {
			Start = [self sSearch:TmpDat Str2:">" Start:Start];
			if (Start == -1) {
				if (strlen(rStr)) {
					m_EditData.Block.LineAttr.Map.Midashi = 1;
					m_EditData.Block.LineAttr.Map.Level = Level;
					[self SetBuf:rStr];
					Midashi = 0;
					Level = 0;
				}
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}
			else {
				Start++;
				goto start6;
			}
		}
		else {
			End = [self sSearch:TmpDat Str2:"<" Start:Start];
			if (End && Start < End) {
				if (strlen(rStr) &&
				    TmpDat[strlen(TmpDat)-1] != 0x20 &&
				    *(TmpDat + Start) != 0x20) {
					strcat(rStr, " ");
				}
				strncat(rStr, TmpDat + Start, End - Start);
				Start = End;
				goto start6;
			}	
			else {
				if (strlen(rStr) &&
				    TmpDat[strlen(TmpDat)-1] != 0x20 &&
				    *(TmpDat + Start) != 0x20) {
					strcat(rStr, " ");
				}
				strcat(rStr, TmpDat + Start);
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}	
		}	
	}
	fclose(InFp);
	[m_EditBuffer Top];
	return 0;
}

- (int)LoadHtmlFile:(const char *)filename ReadMode:(int)RMode {
	FILE *fp;
	FILE *InFp;
	if((InFp = fopen(filename,"r")) == NULL) {
		return(-1);
	}
/*
fp = fopen("log.txt", "a");
fprintf(fp, "%s\n",filename);
fclose(fp);
*/
	if (RMode) {
		[m_EditBuffer End];
	}
	char TmpDat[1024];
	char rStr[1024];
	int Start, End, End2;
	int Midashi = 0;
	int MidashiBak = 0;
	int Level = 0;
	int IsRuby = 0;
	int reply = 0;
	int Ix = 0;
	int Body = 0;
	memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
	memset(TmpDat, 0x00, sizeof(TmpDat));
	while (1) {
		if (MidashiBak) {
			strcpy(TmpDat, "<h");
			TmpDat[2] = MidashiBak + 0x30;
			MidashiBak = 0;
			Ix = 3;
		}
		if((TmpDat[Ix] = fgetc(InFp)) == EOF) {
			break;
		}
		if (IsRuby == 2) {
			IsRuby = 0;
		}
		if (!strncmp(TmpDat + strlen(TmpDat) - 6, "<ruby>", 6)) {
			IsRuby = 1;
		}
		if (!strncmp(TmpDat + strlen(TmpDat) - 7, "</ruby>", 7)) {
			IsRuby = 2;
		}
		if (TmpDat[Ix] != 0x0a &&
		    [self sSearch:TmpDat Str2:"<br />" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"<br>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</p>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h1>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h2>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h3>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h4>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h5>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</h6>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"</title>" Start:0] == -1 &&
		    [self sSearch:TmpDat Str2:"<h1" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h2" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h2" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h3" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h4" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h5" Start:1] <= 0 &&
		    [self sSearch:TmpDat Str2:"<h6" Start:1] <= 0 &&
		    !(strlen(TmpDat) > 600 && !IsRuby && !strncmp(TmpDat + strlen(TmpDat) - 3, "。", 3)) &&
		    !(strlen(TmpDat) > 600 && !IsRuby && !strncmp(TmpDat + strlen(TmpDat) - 2, ". ", 2)) &&
		    !(strlen(TmpDat) > 600 && !IsRuby && !strncmp(TmpDat + strlen(TmpDat) - 2, ", ", 2)) &&
		    !(strlen(TmpDat) > 600 && !IsRuby && !strncmp(TmpDat + strlen(TmpDat) - 1, ">", 1)) &&
		    !(strlen(TmpDat) > 600 && !IsRuby && !strncmp(TmpDat + strlen(TmpDat) - 3, "、", 3))) {
			Ix++;
			continue;
		}
		if (TmpDat[strlen(TmpDat)-1] == 0x0a) {
			TmpDat[strlen(TmpDat) - 1] = 0;
			if (!strlen(TmpDat)) {
				Ix = 0;
				memset(TmpDat, 0x00, sizeof(TmpDat));
				continue;
			}
		}
		if (!strncmp(TmpDat + strlen(TmpDat) - 3, "<h1", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h2", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h3", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h4", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h5", 3) ||
		    !strncmp(TmpDat + strlen(TmpDat) - 3, "<h6", 3)) {
			MidashiBak = TmpDat[strlen(TmpDat) - 1] - 0x30;
			TmpDat[strlen(TmpDat) - 3] = 0;
		}
		Start = 0;
		while (1) {
			if (TmpDat[Start] != 0x20) {
				break;
			}
			Start++;
		}
		if (!TmpDat[Start]) {
			Ix = 0;
			memset(TmpDat, 0x00, sizeof(TmpDat));
			continue;
		}
/*
fp = fopen("log.txt", "a");
fprintf(fp, "%d  %s\n",strlen(TmpDat), TmpDat);
fclose(fp);
*/
		if ([self sSearch:TmpDat Str2:"<body" Start:0] != -1) {
			Body = 1;
		}
		if ([self sSearch:TmpDat Str2:"<h1" Start:0] != -1) {
			Midashi = 1;
			Level = 1;
		}
		if ([self sSearch:TmpDat Str2:"<h2" Start:0] != -1) {
			Midashi = 2;
			Level = 2;
		}
		if ([self sSearch:TmpDat Str2:"<h3" Start:0] != -1) {
			Midashi = 3;
			Level = 4;
		}
		if ([self sSearch:TmpDat Str2:"<h4" Start:0] != -1) {
			Midashi = 4;
			Level = 8;
		}
		if ([self sSearch:TmpDat Str2:"<h5" Start:0] != -1) {
			Midashi = 5;
			Level = 8;
		}
		if ([self sSearch:TmpDat Str2:"<h6" Start:0] != -1) {
			Midashi = 6;
			Level = 8;
		}
		Start = [self sSearch:TmpDat Str2:"title>" Start:0];
		if (!RMode && Start != -1) {
			Start += 6;
			End = [self sSearch:TmpDat Str2:"<" Start:Start+1];
			if (Start < End) {
				memset(rStr, 0x00, sizeof(rStr));
				strncpy(rStr, TmpDat + Start, End - Start);
				m_EditData.Block.LineAttr.Map.Midashi = 1;
				m_EditData.Block.LineAttr.Map.Level = 1;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
			}
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		if (!Body) {
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		memset(rStr, 0x00, sizeof(rStr));
		Start = 0;
		while (1) {
			if (TmpDat[Start] != 0x20) {
				break;
			}
			Start++;
		}
		start6:
/*
fp = fopen("log.txt", "a");
fprintf(fp, "start6  %s\n", TmpDat + Start);
fclose(fp);
*/
		if (!TmpDat[Start]) {
			if (strlen(rStr)) {
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
			}
			memset(TmpDat, 0x00, sizeof(TmpDat));
			Ix = 0;
			continue;
		}
		else if (!strncmp(TmpDat + Start, "<ruby>", 6)) {
			Start = [self sSearch:TmpDat Str2:"<rt>" Start:Start];
			if (Start == -1) {
				if (strlen(rStr)) {
					m_EditData.Block.LineAttr.Map.Midashi = 1;
					m_EditData.Block.LineAttr.Map.Level = Level;
					[self SetBuf:rStr];
					Midashi = 0;
					Level = 0;
				}
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}
			else {
				Start += 4;
				End = [self sSearch:TmpDat Str2:"<" Start:Start];
				if (End && Start < End) {
					strncat(rStr, TmpDat + Start, End - Start);
					Start = [self sSearch:TmpDat Str2:"</ruby>" Start:End];
					if (Start) {
						Start += 7;
						goto start6;
					}
				}
				else {
					m_EditData.Block.LineAttr.Map.Midashi = Midashi;
					m_EditData.Block.LineAttr.Map.Level = Level;
					[self SetBuf:rStr];
					Midashi = 0;
					Level = 0;
					memset(TmpDat, 0x00, sizeof(TmpDat));
					Ix = 0;
					continue;
				}
			}
		}
		else if (TmpDat[Start] == '<') {
			Start = [self sSearch:TmpDat Str2:">" Start:Start];
			if (Start == -1) {
				if (strlen(rStr)) {
					m_EditData.Block.LineAttr.Map.Midashi = 1;
					m_EditData.Block.LineAttr.Map.Level = Level;
					[self SetBuf:rStr];
					Midashi = 0;
					Level = 0;
				}
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}
			else {
				Start++;
				goto start6;
			}
		}
		else {
			End = [self sSearch:TmpDat Str2:"<" Start:Start];
			if (End && Start < End) {
				strncat(rStr, TmpDat + Start, End - Start);
				Start = End;
				goto start6;
			}	
			else {
				strcat(rStr, TmpDat + Start);
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Midashi = 0;
				Level = 0;
				memset(TmpDat, 0x00, sizeof(TmpDat));
				Ix = 0;
				continue;
			}	
		}	
	}
	fclose(InFp);
	[m_EditBuffer Top];
	return(0);
}

- (int)LoadTdvFile:(const char *)filename Head:(TDV_HEAD *)HeadInfo {
	FILE *fp;
	FILE *InFp;
	[m_EditBuffer Remove];
	if((InFp = fopen(filename,"rb")) == NULL) {
		NSString* nsfilename = [NSString stringWithCString: filename encoding:NSUTF8StringEncoding];
		return -1;
	}
	unsigned char TmpDat[256];
	memset(TmpDat,0x00,sizeof(TmpDat));
	if(!fread(TmpDat,256,1,InFp)) {
		fclose(InFp);
		return -1;
	}
	memcpy(HeadInfo,TmpDat,BRLDOC_HEAD_SIZE);
	short IpLen = 0;
	while(1) {
		memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
		if(!fread(m_EditData.Data, 256, 1, InFp)) {
			break;
		}
		[m_EditBuffer Ins:m_EditData.Data];
	}
	fclose(InFp);
	[m_EditBuffer SetLine:HeadInfo->CurLine];
	return 0;
}

- (BOOL)SaveTdvFile:(const char *)filename Head:(TDV_HEAD *)HeadInfo {
	FILE *OutFp;
	HeadInfo->CurLine = [m_EditBuffer IsCurLine];
	if((OutFp = fopen(filename,"w+b")) == NULL) {
		return FALSE;
	}
	if(!fwrite(HeadInfo,BRLDOC_HEAD_SIZE,1,OutFp)) {
		fclose(OutFp);
		unlink(filename);
		return FALSE;
	}
	int Ix;
	fflush(OutFp);
	[m_EditBuffer Top];
	while (1) {
		memcpy(m_EditData.Data, [m_EditBuffer GetDat], BRLDOC_DAT_SIZE);
		if(!fwrite(m_EditData.Data, 256, 1, OutFp)) {
			break;
		}
		fflush(OutFp);
		if (![m_EditBuffer NextLine]) {
			break;
		}
	}
	fflush(OutFp);
	fclose(OutFp);
	[m_EditBuffer SetLine:HeadInfo->CurLine];
	return TRUE;
}

- (int)SaveHead:(const char *)filename Head:(TDV_HEAD *)HeadInfo {
	FILE *OutFp;
	if((OutFp = fopen(filename,"r+b")) == NULL) {
		return -1;
	}
	fseek(OutFp,0L,SEEK_SET);
	fwrite(HeadInfo, 256, 1, OutFp);	// ヘッダ保存
	fflush(OutFp);
	fclose(OutFp);
	return 0;
}

// 行属性を設定する関数
- (void)SetLineHead {
	unsigned char LAttr = m_EditData.Block.LineAttr.Attr&0xdf;
	if(strchr((char *)m_EditData.Block.Data.Line,PR_MARK) != NULL) {
			LAttr += 0x20;
	}
	if(LAttr&CL_STAB_ATTR*16) {
		LAttr &= 0x3f;
	}
	m_EditData.Block.LineAttr.Attr = LAttr;
}
// 行内の最大文字取得関数
- (int)EditDataLen {
	int index = 0;
	while(1) {
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == 0x00) {
			break;
		}
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == CR_MARK) {
			index |= 0x0100;
		}
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == PR_MARK) {
			index |= 0x0200;
		}
		index++;
	}
	return(index);
}

- (int)sSearch:(char *)Str1 Str2:(char *)Str2 Start:(int)Start {
	int Ix = 0;
	int Len1 = strlen(Str1);
	int Len2 = strlen(Str2);
	while (Str1[Start]) {
		for (Ix = 0; Ix < Len2; Ix++) {
			if ((Start + Ix) > Len1) {
				break;
			}
			if (Str1[Start + Ix] == Str2[Ix] ||
			    (Str1[Start + Ix] >= 0x41 &&
			     Str1[Start + Ix] <= 0x5a &&
			     (Str1[Start+ Ix] + 0x20) == Str2[Ix])) {
				continue;
			}
			else {
				break;
			}
		}
		if (Ix == Len2) {
			return Start;
		}
		Start++;
	}
	return -1;
}

- (int)IsKugiri:(char *)Str {
	int Start = 251;
	while (Start > 0) {
		if (!strncmp(Str + Start, "。", 3) ||
		    !strncmp(Str + Start, "、", 3) ||
		    !strncmp(Str + Start, "・", 3) ||
		    !strncmp(Str + Start, "」", 3) ||
		    !strncmp(Str + Start, "）", 3) ||
		    !strncmp(Str + Start, "　", 3)) {
			return Start;
		}
		Start--;
	}
	return 0;
}

- (void)SetRuby:(char *)Str rStr:(char *)rStr {
FILE *fp;
	int Start = 0;
	int End;
	Start = [self sSearch:Str Str2:"sent id=" Start:0];
	if (Start != -1) {
		Start = [self sSearch:Str Str2:"\">" Start:Start+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End && (Start + 2) < End) {
			Start += 2;
			strncpy(rStr, Str + Start, End - Start);
		}
	}
	else {
		Start = 0;
	}
	start:
	End = [self sSearch:Str Str2:"<span class=\"rt\">" Start:Start];
	if (End != -1) {
		Start = [self sSearch:Str Str2:"\">" Start:End+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && Start < End) {
			Start += 2;
			strncat(rStr, Str + Start, End - Start);
		}
	}
	End = [self sSearch:Str Str2:"</span></span>" Start:Start];
	if (End != -1) {
		Start = End + 14;
		if (*(Str + Start) == '<') {
			goto start;
		}
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && Start < End) {
			strncat(rStr, Str + Start, End - Start);
		}
		else {
			End = Start;
		}
		if (!*(Str + End)) {
			return;
		}
	}
	if (!strncmp(Str + End, "</sent>", 7)) {
		return;
	}
	else if ([self sSearch:Str Str2:"<span class=\"ruby\">" Start:End] != -1) {
		goto start;
	}
	else {
		return;
	}
}

- (void)SetBuf:(char *)Str {
	[self SetCho:(unsigned char *)Str];
	int Ix;
	start3:
	if (strlen(Str) <= 254) {
		strcpy(m_EditData.Data+2, Str);
		[m_EditBuffer Ins:m_EditData.Data];
		memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
		return;
	}
	else {
		Ix = [self IsKugiri:Str];
		if (Ix) {
			strncpy(m_EditData.Data+2, Str, Ix+3);
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data+2,0x00,BRLDOC_DAT_SIZE-2);
			strcpy(Str, Str + Ix+3);
			goto start3;
		}
		else {
			strncpy(m_EditData.Data+2, Str, 254);
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data+2,0x00,BRLDOC_DAT_SIZE-2);
			strcpy(Str, Str + 254);
			goto start3;
		}
	}
}

- (void)SetCho:(unsigned char *)Str {
	int Ix = 0;
	while (Str[Ix]) {
		if (!strncmp(Str + Ix, "ー", 3) && Ix >= 3) {
			if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] >= 0x81 &&
			    Str[Ix-1] <= 0xa3) {
				int Jx = Str[Ix-1] - 0x81;
				Jx %= 10;
				Jx /= 2;
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x80+Jx*2+2;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] >= 0xa4 &&
			    Str[Ix-1] <= 0xa9) {
				int Jx = Str[Ix-1] - 0xa0;
				Jx %= 10;
				Jx /= 2;
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x80+Jx*2+2;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] >= 0xaa &&
			    Str[Ix-1] <= 0xae) {
				int Jx = Str[Ix-1] - 0xaa;
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x80+Jx*2+2;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] >= 0xaf &&
			    Str[Ix-1] <= 0xbd) {
				int Jx = Str[Ix-1] - 0xaf;
				Jx /= 3;
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x80+Jx*2+2;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    Str[Ix-1] >= 0x89 &&
			    Str[Ix-1] <= 0x8d) {
				int Jx = Str[Ix-1] - 0x89;
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x80+Jx*2+2;
				Ix += 3;
				continue;
			}	
			else if ((Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] == 0xbe) ||
			    (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    (Str[Ix-1] == 0x83 ||
			     Str[Ix-1] == 0x84 ||
			     Str[Ix-1] == 0x8e ||
			     Str[Ix-1] == 0x8f))) {
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x82;
				Ix += 3;
				continue;
			}	
			else if ((Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x81 &&
			    Str[Ix-1] == 0xbf) ||
			    (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    Str[Ix-1] == 0x90)) {
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x84;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    (Str[Ix-1] == 0x80 ||
			     Str[Ix-1] == 0x85 ||
			     Str[Ix-1] == 0x86 ||
			     Str[Ix-1] == 0x90 ||
			     Str[Ix-1] == 0x93)) {
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x86;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    (Str[Ix-1] == 0x81 ||
			     Str[Ix-1] == 0x91)) {
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x88;
				Ix += 3;
				continue;
			}	
			else if (Str[Ix-3] == 0xe3 &&
			    Str[Ix-2] == 0x82 &&
			    (Str[Ix-1] == 0x82 ||
			     Str[Ix-1] == 0x87 ||
			     Str[Ix-1] == 0x88 ||
			     Str[Ix-1] == 0x92)) {
				Str[Ix] = 0xe3;
				Str[Ix+1] = 0x81;
				Str[Ix+2] = 0x8a;
				Ix += 3;
				continue;
			}	
		}
		Ix++;
	}
}
@end
