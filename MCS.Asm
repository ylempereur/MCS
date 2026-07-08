;SAVE"MCS.Asm"
*--------------------------------
;
; MCS v1.1
;
;        Yves Lempereur
;
; MODIFICATION HISTORY
;        07/02/87  YL    Version 1.0d
;        08/26/88  YL    Version 1.1
;
*--------------------------------
         LIST    OFF
*--------------------------------
         INCLUDE ":Sources:Library.Asm"
         INCLUDE ":Sources:Equates.Asm"
*--------------------------------
development      EQU  $20
alpha            EQU  $40
beta             EQU  $60
release          EQU  $80
verUS            EQU  0
;
everyEvent       EQU  -1
;
srcCopy          EQU  0
srcOr            EQU  1
teJustLeft       EQU  0
teJustCenter     EQU  1
;
eofErr           EQU  -39
fnfErr           EQU  -43
;
putDlgID         EQU  -3999
getDlgID         EQU  -4000
;
dBounds          EQU  $0
aBounds          EQU  $0
;
MenuBarID        EQU  128
;
AppleID          EQU  128
AboutItem        EQU  1
;
FileID           EQU  129
DialItem         EQU  1
HangupItem       EQU  2
SettingsItem     EQU  4
QuitItem         EQU  6
;
EditID           EQU  130
UndoItem         EQU  1
CutItem          EQU  3
CopyItem         EQU  4
PasteItem        EQU  5
ClearItem        EQU  6
;
MSG      EQU     0
ACK      EQU     1
NAK      EQU     2
CAN      EQU     3
;
STX      EQU     $02
LF       EQU     $0A
FF       EQU     $0C
CR       EQU     $0D
ESC      EQU     $1B
*--------------------------------
         GLOBAL  4768
;
sDial            DEFS 256
sInit            DEFS 256
sRate            DEFS W
sBaud            DEFS W
sMode            DEFS W
sPort            DEFS W
;
wStorage         DEFS $9C
BlkBufR          DEFS 128
BlkBufS          DEFS 128
ChatStr          DEFS 82
InpBuf           DEFS 80
ParaBlk          DEFS 80
SFReply          DEFS 74
DeskName         DEFS 32
EventRecord      DEFS 16
TempRect         DEFS 8
;
U.Select         DEFS W
U.Type           DEFS L
U.Creator        DEFS L
U.Flags          DEFS W
U.Location       DEFS L
U.Folder         DEFS W
U.Locked         DEFS W
U.DataLen        DEFS L
U.RsrcLen        DEFS L
U.FlCrDat        DEFS L
U.FlMdDat        DEFS L
U.RefNum         DEFS W
U.Volume         DEFS W
U.Name           DEFS 64
U.OwnBuf         DEFS 522
U.MaxBlk         DEFS W
U.Block          DEFS W
;
D.Select         DEFS W
D.Type           DEFS L
D.Creator        DEFS L
D.Flags          DEFS W
D.Location       DEFS L
D.Folder         DEFS W
D.Locked         DEFS W
D.DataLen        DEFS L
D.RsrcLen        DEFS L
D.FlCrDat        DEFS L
D.FlMdDat        DEFS L
D.RefNum         DEFS W
D.Volume         DEFS W
D.Name           DEFS 64
D.OwnBuf         DEFS 522
D.MaxBlk         DEFS W
D.Block          DEFS W
;
NameQueue        DEFS L
NameHandle       DEFS L
TheWindow        DEFS L
whichWindow      DEFS L
IBeam            DEFS L
Watch            DEFS L
CarTime          DEFS L
MenuID           DEFS W
MenuItem         DEFS W
ShftReg          DEFS L
CarPos           DEFS W
CarAct           DEFS B
CarOn            DEFS B
InpOn            DEFS B
RsrcChanged      DEFS B
LineFlag         DEFS B
ModemFlag        DEFS B
Quitting         DEFS B
Finished         DEFS B
LogoFlg          DEFS B
Filler           DEFS B          ;
;
xmsBufR          DEFS L
xmsBufS          DEFS L
xmsLenR          DEFS W
xmsLenS          DEFS W
xmsDCD           DEFS B
xmsDummy         DEFS B          ;
padPW            DEFS B
padPS            DEFS B
padPR            DEFS B
padPJ            DEFS B
padTO            DEFS L
padT15           DEFS L
padT17           DEFS L
padOvfR          DEFS B
padFlwS          DEFS B
padLenS          DEFS B*4
padBufS          DEFS 128*4
lnkT10           DEFS L
lnkCRC           DEFS W
lnkCntR          DEFS W
lnkLenR          DEFS B
lnkIDR           DEFS B
lnkBufR          DEFS 128
lnkBufS          DEFS 135
lnkFlgR          DEFS B
lnkRCI           DEFS W
lnkRCO           DEFS W
lnkPCR           DEFS 50
lnkPCS           DEFS 50
lnkBCR           DEFS 1024
                 DEFS *&1
;
                 DEFS grafSize
;
         ENDG
*--------------------------------
         TFILE   "MCS.Bin"
*--------------------------------
         RFILE   "MCS",APPL,MCS1,$2000
*================================
         SEG     0,resPurgeable!resPreLoad,Var.Len,32
SEG0
SEG_1    JP      Start,1
END_1
END0
         ENDR
*================================
         SEG     1,resLocked!resPreLoad
*--------------------------------
Start    BSR     DataInit
         BSR     MxApplZone
         _MoreMasters
         PEA     -4(A5)
         _InitGraf
         _InitFonts
         _InitWindows
         _InitMenus
         _TEInit
         CLR.L   -(SP)
         _InitDialogs
         MOVE.L  #$0000FFFF,D0
         _FlushEvents
         BSR     SetUpMenus
         BSR     SetUpCursors
         BSR     NameInit
         BSR     LoadCNFG
         BSR     Mopen
         BSR     Mreset
         BSR     wOpen
         BSR     VarInit
*--------------------------------
MainLoop _SystemTask
         BSR     FixCursor
         BSR     IdleCar
         BSR     DoEvent
         TST.B   Finished(A5)
         BEQ.S   MainLoop
*--------------------------------
         BSR     WatchCur
         BSR     wClose
         BSR     Mclose
         BSR     SaveCNFG
         _ExitToShell
*--------------------------------
DoEvent  CLR.B   -(SP)
         MOVE    #everyEvent,-(SP)
         PEA     EventRecord(A5)
         _GetNextEvent
         TST.B   (SP)+
         BEQ.S   .0
         MOVE    EventRecord+evtNum(A5),D0
         ADD     D0,D0
         MOVE    .10(PC,D0),D0
         JSR     .10(PC,D0)
         BRA.S   .1
.0       BSR     DoCom
         TST.B   Quitting(A5)
         BEQ.S   .1
         BSR     DoHangup
         ST      Finished(A5)
.1       RTS
.10      DATA    /.1-.10         ; null
         DATA    /MseDown-.10    ; mouse down
         DATA    /.1-.10         ; mouse up
         DATA    /KeyDown-.10    ; key down
         DATA    /.1-.10         ; key up
         DATA    /KeyDown-.10    ; auto-key
         DATA    /DoUpdate-.10   ; update
         DATA    /.1-.10         ; disk inserted
         DATA    /DoActivate-.10 ; activate
         DATA    /.1-.10         ;
         DATA    /.1-.10         ; network
         DATA    /.1-.10         ; device driver
         DATA    /.1-.10         ; application-defined
         DATA    /.1-.10         ; application-defined
         DATA    /.1-.10         ; application-defined
         DATA    /.1-.10         ; suspend/resume
*--------------------------------
KeyDown  TST.B   Quitting(A5)
         BNE.S   .1
         MOVE    EventRecord+evtMeta(A5),D0
         BTST    #8,D0
         BEQ.S   .0
         BSR     ArrowCur
         BSR     UpdAMenu
         BSR     UpdFMenu
         BSR     UpdEMenu
         CLR.L   -(SP)
         MOVE.L  EventRecord+evtMessage(A5),D0
         MOVE    D0,-(SP)
         _MenuKey
         MOVE.L  (SP)+,MenuID(A5)
         BSR     DoMenu
         BRA.S   .1
.0       BSR     DoKey
.1       RTS
*--------------------------------
MseDown  TST.B   Quitting(A5)
         BNE.S   .0
         CLR     -(SP)
         MOVE.L  EventRecord+evtMouse(A5),-(SP)
         PEA     whichWindow(A5)
         _FindWindow
         MOVE    (SP)+,D0
         ADD     D0,D0
         MOVE    .10(PC,D0),D0
         JSR     .10(PC,D0)
.0       RTS
.10      DATA    /.0-.10         ; inDesk
         DATA    /inMenuB-.10    ; inMenuBar
         DATA    /SysEvnt-.10    ; inSysWindow
         DATA    /DoCntnt-.10    ; inContent
         DATA    /.0-.10         ; inDrag
         DATA    /.0-.10         ; inGrow
         DATA    /.0-.10         ; inGoAway
         DATA    /.0-.10         ; inZoomIn
         DATA    /.0-.10         ; inZoomOut
*--------------------------------
inMenuB  BSR     ArrowCur
         BSR     UpdAMenu
         BSR     UpdFMenu
         BSR     UpdEMenu
         CLR.L   -(SP)
         MOVE.L  EventRecord+evtMouse(A5),-(SP)
         _MenuSelect
         MOVE.L  (SP)+,MenuID(A5)
         BSR     DoMenu
         RTS
*--------------------------------
DoMenu   MOVE    MenuID(A5),D0
         SUB     #AppleID,D0
         BLO.S   .0
         ADD     D0,D0
         MOVE    .10(PC,D0),D0
         JSR     .10(PC,D0)
.0       CLR     -(SP)
         _HiliteMenu
         RTS
.10      DATA    /MnApple-.10    ; Apple
         DATA    /MnuFile-.10    ; File
         DATA    /MnuEdit-.10    ; Edit
*--------------------------------
MnApple  MOVE    MenuItem(A5),D0
         CMP     #AboutItem,D0
         BNE.S   .0
         BSR     DoAbout
         BRA.S   .1
.0       BSR     DoDesk
.1       RTS
*--------------------------------
DoAbout  BSR     Cls
         MOVE    #-1,ACount
         MOVE    #128,-(SP)
         BSR     CenterAlert
         CLR     -(SP)
         MOVE    #128,-(SP)
         CLR.L   -(SP)
         _Alert
         TST     (SP)+
         RTS
*--------------------------------
DoDesk   LINK    A6,#-256
         BSR     Cls
         CLR.L   -(SP)
         MOVE    MenuID(A5),-(SP)
         _GetMHandle
         MOVE    MenuItem(A5),-(SP)
         PEA     -256(A6)
         _GetItem
         CLR     -(SP)
         PEA     -256(A6)
         _OpenDeskAcc
         TST     (SP)+
         UNLK    A6
         RTS
*--------------------------------
MnuFile  MOVE    MenuItem(A5),D0
         ADD     D0,D0
         MOVE    .10(PC,D0),D0
         JSR     .10(PC,D0)
.0       RTS
.10      DATA    /.0-.10         ; File
         DATA    /DoDial-.10     ; Dial
         DATA    /DoHangup-.10   ; Hang Up
         DATA    /.0-.10         ; -
         DATA    /DoSetup-.10    ; Settings…
         DATA    /.0-.10         ; -
         DATA    /DoQuit-.10     ; Quit
*--------------------------------
DoDial   TST.B   ModemFlag(A5)
         BEQ.S   .1
         TST.B   LineFlag(A5)
         BNE.S   .1
         BSR     WatchCur
         BSR     T_Call
         BNE.S   .0
         BSR     OnLine
         LEA     BlkBufR(A5),A0
         MOVE    #128,D0
         BSR     T_Receive
.0       BSR     ArrowCur
.1       RTS
*--------------------------------
DoHangup TST.B   ModemFlag(A5)
         BEQ.S   .0
         TST.B   LineFlag(A5)
         BEQ.S   .0
         BSR     WatchCur
         BSR     OfLine
         BSR     T_Hangup
         BSR     ArrowCur
.0       RTS
*--------------------------------
* PROCEDURE DoSetup;
*--------------------------------
theDialog        SET  -4
tempBaud         SET  -6
tempMode         SET  -8
tempPort         SET  -10
itemHit          SET  -12
LocalSize        SET  -12
*--------------------------------
DoSetup  LINK    A6,#LocalSize
         BSR     WatchCur
         BSR     Cls
         MOVE    #200,-(SP)
         BSR     CenterDialog
         CLR.L   -(SP)
         MOVE    #200,-(SP)
         CLR.L   -(SP)
         MOVE.L  MinusOne,-(SP)
         _GetNewDialog
         MOVE.L  (SP)+,theDialog(A6)
         MOVE    sBaud(A5),tempBaud(A6)
         MOVE    sMode(A5),tempMode(A6)
         MOVE    sPort(A5),tempPort(A6)
         ADD     #3,tempBaud(A6)
         ADD     #7,tempMode(A6)
         ADD     #9,tempPort(A6)
         MOVE.L  theDialog(A6),-(SP)
         MOVE    tempBaud(A6),-(SP)
         MOVE    #1,-(SP)
         BSR     SetValue
         MOVE.L  theDialog(A6),-(SP)
         MOVE    tempMode(A6),-(SP)
         MOVE    #1,-(SP)
         BSR     SetValue
         MOVE.L  theDialog(A6),-(SP)
         MOVE    tempPort(A6),-(SP)
         MOVE    #1,-(SP)
         BSR     SetValue
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #11,-(SP)
         PEA     sDial(A5)
         BSR     SetText
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #12,-(SP)
         PEA     sInit(A5)
         BSR     SetText
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #18,-(SP)
         BSR     UserItem
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #11,-(SP)
         MOVE    #0,-(SP)
         MOVE    #32767,-(SP)
         _SelIText
         MOVE.L  theDialog(A6),-(SP)
         _ShowWindow
         BSR     ArrowCur
.0       CLR.L   -(SP)
         PEA     itemHit(A6)
         _ModalDialog
         MOVE    itemHit(A6),D0
         CMP     #1,D0
         BNE.S   .1
         BSR     WatchCur
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #11,-(SP)
         PEA     sDial(A5)
         BSR     GetText
         MOVE.L  theDialog(A6),-(SP)
         MOVE    #12,-(SP)
         PEA     sInit(A5)
         BSR     GetText
         MOVE.L  theDialog(A6),-(SP)
         _DisposDialog
         SUB     #3,tempBaud(A6)
         SUB     #7,tempMode(A6)
         SUB     #9,tempPort(A6)
         MOVE    tempBaud(A6),sBaud(A5)
         MOVE    tempMode(A6),sMode(A5)
         MOVE    tempPort(A6),D0
         CMP     sPort(A5),D0
         BEQ.S   .10
         BSR     Mclose
         MOVE    tempPort(A6),sPort(A5)
.10      BSR     Mopen
         BSR     Mreset
         ST      RsrcChanged(A5)
         BSR     ArrowCur
         UNLK    A6
         RTS
.1       CMP     #2,D0
         BNE.S   .2
         BSR     WatchCur
         MOVE.L  theDialog(A6),-(SP)
         _DisposDialog
         BSR     ArrowCur
         UNLK    A6
         RTS
.2       CMP     #6,D0
         BHI.S   .3
         MOVE    tempBaud(A6),D1
         MOVE    D0,tempBaud(A6)
         BRA.S   .5
.3       CMP     #8,D0
         BHI.S   .4
         MOVE    tempMode(A6),D1
         MOVE    D0,tempMode(A6)
         BRA.S   .5
.4       CMP     #10,D0
         BHI     .0
         MOVE    tempPort(A6),D1
         MOVE    D0,tempPort(A6)
.5       MOVE.L  theDialog(A6),-(SP)
         MOVE    D1,-(SP)
         MOVE    #0,-(SP)
         BSR     SetValue
         MOVE.L  theDialog(A6),-(SP)
         MOVE    itemHit(A6),-(SP)
         MOVE    #1,-(SP)
         BSR     SetValue
         BRA     .0
*--------------------------------
DoQuit   ST      Quitting(A5)
         RTS
*--------------------------------
MnuEdit  CLR.B   -(SP)
         MOVE    MenuItem(A5),D0
         SUBQ    #1,D0
         MOVE    D0,-(SP)
         _SysEdit
         TST.B   (SP)+
         RTS
*--------------------------------
SysEvnt  PEA     EventRecord(A5)
         MOVE.L  whichWindow(A5),-(SP)
         _SystemClick
         RTS
*--------------------------------
DoCntnt  CLR.L   -(SP)
         _FrontWindow
         MOVE.L  (SP)+,D0
         CMP.L   whichWindow(A5),D0
         BEQ.S   .0
         MOVE.L  whichWindow(A5),-(SP)
         _SelectWindow
         BRA.S   .1
.0       BSR     DoMouse
.1       RTS
*--------------------------------
DoUpdate MOVE.L  EventRecord+evtMessage(A5),whichWindow(A5)
         MOVE.L  whichWindow(A5),-(SP)
         _BeginUpdate
         MOVE.L  whichWindow(A5),-(SP)
         _SetPort
         MOVE.L  whichWindow(A5),A0
         PEA     portRect(A0)
         _EraseRect
         BSR     UpdtDspU
         BSR     UpdtDspD
         BSR     DspScrn
         MOVE.L  whichWindow(A5),-(SP)
         _EndUpdate
         RTS
*--------------------------------
DoActivate
         MOVE.L  EventRecord+evtMessage(A5),-(SP)
         _SetPort
         MOVE    EventRecord+evtMeta(A5),D0
         BTST    #0,D0
         BNE.S   .0
         BSR     DeActCar
         RTS
.0       BSR     ActCar
         RTS
*--------------------------------
DoKey    TST.B   InpOn(A5)
         BEQ     .14
         TST.B   CarAct(A5)
         BEQ     .14
         _ObscureCursor
         BSR     OffCar
         MOVE.L  EventRecord+evtMessage(A5),D0
         CMP.B   #$20,D0
         BLO.S   .2
         CMP     #80,CarPos(A5)
         BHS     .13
         LEA     InpBuf+79(A5),A0
         MOVEQ   #79,D1
         SUB     CarPos(A5),D1
         BRA.S   .1
.0       MOVE.B  -(A0),1(A0)
.1       DBRA    D1,.0
         MOVE.B  D0,(A0)
         ADDQ    #1,CarPos(A5)
         BRA     .12
.2       CMP.B   #$08,D0
         BNE.S   .5
         TST     CarPos(A5)
         BEQ     .13
         SUBQ    #1,CarPos(A5)
         LEA     InpBuf(A5),A0
         ADD     CarPos(A5),A0
         MOVEQ   #79,D1
         SUB     CarPos(A5),D1
         BRA.S   .4
.3       MOVE.B  1(A0),(A0)+
.4       DBRA    D1,.3
         MOVE.B  #' ,(A0)
         BRA.S   .12
.5       CMP.B   #$09,D0
         BNE.S   .6
         CMP     #80,CarPos(A5)
         BHS.S   .13
         ADD     #8,CarPos(A5)
         AND     #$FFF8,CarPos(A5)
         BRA.S   .13
.6       CMP.B   #$1C,D0
         BNE.S   .7
         TST     CarPos(A5)
         BEQ.S   .13
         SUBQ    #1,CarPos(A5)
         BRA.S   .13
.7       CMP.B   #$1D,D0
         BNE.S   .8
         CMP     #80,CarPos(A5)
         BHS.S   .13
         ADDQ    #1,CarPos(A5)
         BRA.S   .13
.8       CMP.B   #$1E,D0
         BNE.S   .9
         CLR     CarPos(A5)
         BRA.S   .13
.9       CMP.B   #$1F,D0
         BNE.S   .10
         MOVE    #80,CarPos(A5)
         BRA.S   .13
.10      CMP.B   #$1B,D0
         BNE.S   .15
         LEA     InpBuf(A5),A0
         MOVEQ   #80/4-1,D1
         MOVE.L  #$20202020,D0
.11      MOVE.L  D0,(A0)+
         DBRA    D1,.11
         CLR     CarPos(A5)
.12      BSR     DspI
.13      BSR     OnCar
.14      RTS
.15      CMP.B   #$03,D0
         BEQ.S   .16
         CMP.B   #$0D,D0
         BNE.S   .13
.16      LEA     InpBuf+80(A5),A0
         MOVEQ   #80-1,D1
         MOVEQ   #$20,D0
.17      CMP.B   -(A0),D0
         DBNE    D1,.17
         ADDQ    #1,D1
         LEA     InpBuf(A5),A0
         LEA     ChatStr(A5),A1
         MOVE.B  D1,(A1)+
         MOVEQ   #$20,D0
         BRA.S   .19
.18      MOVE.B  (A0),(A1)+
         MOVE.B  D0,(A0)+
.19      DBRA    D1,.18
         CLR     CarPos(A5)
         LEA     ChatStr(A5),A0
         TST.B   (A0)
         BEQ.S   .12
         BSR     DspS
         BSR     DspI
         BSR     OffInp
         RTS
*--------------------------------
DoMouse  TST.B   InpOn(A5)
         BEQ.S   .0
         TST.B   CarAct(A5)
         BEQ.S   .0
         PEA     EventRecord+evtMouse(A5)
         _GlobalToLocal
         CLR.B   -(SP)
         MOVE.L  EventRecord+evtMouse(A5),-(SP)
         PEA     .10(PC)
         _PtInRect
         TST.B   (SP)+
         BEQ.S   .0
         BSR     OffCar
         CLR.L   D0
         MOVE    EventRecord+evtMouse+h(A5),D0
         SUB     #009-03,D0
         DIVU    #06,D0
         MOVE    D0,CarPos(A5)
         BSR     OnCar
.0       RTS
.10      DATA    /216,/006,/227,/492
*--------------------------------
DoCom    TST.B   ModemFlag(A5)
         BEQ     .7
         TST.B   LineFlag(A5)
         BNE.S   .0
         BSR     T_Listen
         BNE     .7
         BSR     OnLine
         LEA     BlkBufR(A5),A0
         MOVE    #128,D0
         BSR     T_Receive
         BRA     .7
.0       BSR     T_Status
         TST.B   D3
         BNE.S   .1
         BSR     WatchCur
         BSR     OfLine
         BSR     T_Hangup
         BSR     ArrowCur
         BRA.S   .7
.1       MOVE    xmsLenR(A5),D1
         SUB     #128,D1
         BEQ.S   .6
         LEA     BlkBufR(A5),A0
         NEG     D1
         CMP     #128,D1
         BNE.S   .2
         MOVEQ   #0,D0
         BSR     DoRD
         BRA.S   .5
.2       CMP     #2,D1
         BLO.S   .5
         MOVE    (A0)+,D0
         SUBQ    #2,D1
         CMP     #MSG,D0
         BNE.S   .3
         BSR     DoRC
         BRA.S   .5
.3       CMP     #CAN,D0
         BNE.S   .4
         BSR     DoRD
         BRA.S   .5
.4       BSR     DoRU
.5       LEA     BlkBufR(A5),A0
         MOVE    #128,D0
         BSR     T_Receive
.6       TST     xmsLenS(A5)
         BNE.S   .7
         BSR     DoSC
         TST     xmsLenS(A5)
         BNE.S   .7
         BSR     DoSD
         TST     xmsLenS(A5)
         BNE.S   .7
         BSR     DoSU
.7       RTS
*--------------------------------
DoRC     CMP     #80,D1
         BLS.S   .0
         MOVEQ   #80,D1
.0       MOVE.B  D1,-(A0)
         BSR     DspS
         RTS
DoSC     TST.B   InpOn(A5)
         BNE.S   .2
         TST.B   ChatStr(A5)
         BEQ.S   .1
         LEA     BlkBufS(A5),A0
         CLR     D0
         MOVE    #MSG,0(A0,D0)
         ADDQ    #2,D0
         LEA     ChatStr(A5),A1
         CLR     D1
         MOVE.B  (A1)+,D1
.0       MOVE.B  (A1)+,0(A0,D0)
         ADDQ    #1,D0
         SUBQ    #1,D1
         BNE.S   .0
         BSR     Xoutput
.1       BSR     OnInp
.2       RTS
*--------------------------------
DoRU     MOVEQ   #0,D6
         BRA.S   DoU
DoSU     MOVEQ   #1,D6
DoU      MOVE    U.Select(A5),D7
         ADD     D7,D7
         ADD     D6,D7
         ADD     D7,D7
         MOVE    .999(PC,D7),D7
         JMP     .999(PC,D7)
.999     DATA    /.00-.999
         DATA    /.01-.999
         DATA    /.10-.999
         DATA    /.11-.999
         DATA    /.20-.999
         DATA    /.21-.999
         DATA    /.30-.999
         DATA    /.31-.999
         DATA    /.40-.999
         DATA    /.41-.999
         DATA    /.50-.999
         DATA    /.51-.999
         DATA    /.60-.999
         DATA    /.61-.999
.00      RTS
.01      BSR     GetName
         BEQ.S   .00
         LEA     ParaBlk(A5),A0
         LEA     U.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    U.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         CLR     ioFDirIndex(A0)
         _GetFileInfo
         MOVE    ioResult(A0),D0
         BNE     .46
         MOVE.L  32(A0),U.Type(A5)
         MOVE.L  36(A0),U.Creator(A5)
         MOVE    40(A0),U.Flags(A5)
         MOVE.L  42(A0),U.Location(A5)
         MOVE    46(A0),U.Folder(A5)
         MOVE    30(A0),U.Locked(A5)
         AND     #$0100,U.Locked(A5)
         MOVE.L  54(A0),U.DataLen(A5)
         MOVE.L  64(A0),U.RsrcLen(A5)
         MOVE.L  72(A0),U.FlCrDat(A5)
         MOVE.L  76(A0),U.FlMdDat(A5)
         BSR     InitBlkU
         LEA     BlkBufS(A5),A0
         MOVEQ   #128/4-1,D0
.02      CLR.L   (A0)+
         DBRA    D0,.02
         LEA     U.Name(A5),A0
         LEA     BlkBufS+1(A5),A1
         CLR     D0
         MOVE.B  (A0),D0
.03      MOVE.B  (A0)+,(A1)+
         DBRA    D0,.03
         LEA     U.Type(A5),A0
         LEA     BlkBufS+65(A5),A1
         MOVEQ   #34-1,D0
.04      MOVE.B  (A0)+,(A1)+
         DBRA    D0,.04
         LEA     BlkBufS(A5),A0
         MOVE    #128,D0
         BSR     Xoutput
         MOVE    #1,U.Select(A5)
         RTS
.10      CMP     #ACK,D0
         BNE     .46
         TST.L   U.DataLen(A5)
         BEQ     .25
         LEA     ParaBlk(A5),A0
         LEA     U.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    U.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         MOVE.B  #fsRdPerm,ioPermssn(A0)
         LEA     U.OwnBuf(A5),A1
         MOVE.L  A1,ioMisc(A0)
         _Open
         MOVE    ioResult(A0),D0
         BNE     .46
         MOVE    ioRefNum(A0),U.RefNum(A5)
         MOVE    #2,U.Select(A5)
.11      RTS
.20      BRA     .45
.21      LEA     ParaBlk(A5),A0
         MOVE    U.RefNum(A5),ioRefNum(A0)
         LEA     BlkBufS(A5),A1
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  #128,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Read
         MOVE    ioResult(A0),D0
         BEQ.S   .22
         CMP     #eofErr,D0
         BNE     .45
.22      MOVE.L  ioActCount(A0),D0
         SUB.L   D0,U.DataLen(A5)
         LEA     BlkBufS(A5),A0
.23      CMP     #128,D0
         BHS.S   .24
         CLR.B   0(A0,D0)
         ADDQ    #1,D0
         BRA.S   .23
.24      BSR     Xoutput
         ADDQ    #1,U.Block(A5)
         BSR     DispBlkU
         TST.L   U.DataLen(A5)
         BNE.S   .26
         LEA     ParaBlk(A5),A0
         MOVE    U.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    ioResult(A0),D0
         BNE     .45
.25      TST.L   U.RsrcLen(A5)
         BEQ     .35
         LEA     ParaBlk(A5),A0
         LEA     U.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    U.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         MOVE.B  #fsRdPerm,ioPermssn(A0)
         LEA     U.OwnBuf(A5),A1
         MOVE.L  A1,ioMisc(A0)
         _OpenRF
         MOVE    ioResult(A0),D0
         BNE     .46
         MOVE    ioRefNum(A0),U.RefNum(A5)
         MOVE    #3,U.Select(A5)
.26      RTS
.30      BRA     .45
.31      LEA     ParaBlk(A5),A0
         MOVE    U.RefNum(A5),ioRefNum(A0)
         LEA     BlkBufS(A5),A1
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  #128,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Read
         MOVE    ioResult(A0),D0
         BEQ.S   .32
         CMP     #eofErr,D0
         BNE.S   .45
.32      MOVE.L  ioActCount(A0),D0
         SUB.L   D0,U.RsrcLen(A5)
         LEA     BlkBufS(A5),A0
.33      CMP     #128,D0
         BHS.S   .34
         CLR.B   0(A0,D0)
         ADDQ    #1,D0
         BRA.S   .33
.34      BSR     Xoutput
         ADDQ    #1,U.Block(A5)
         BSR     DispBlkU
         TST.L   U.RsrcLen(A5)
         BNE.S   .36
         LEA     ParaBlk(A5),A0
         MOVE    U.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    ioResult(A0),D0
         BNE.S   .45
.35      MOVE    #4,U.Select(A5)
.36      RTS
.40      CMP     #ACK,D0
         BNE.S   .46
         CLR     U.Select(A5)
         BSR     UpdtDspU
.41      RTS
.45      MOVE    D0,-(SP)
         LEA     ParaBlk(A5),A0
         MOVE    U.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    (SP)+,D0
.46      MOVE    #5,U.Select(A5)
.50      RTS
.51      LEA     BlkBufS(A5),A0
         CLR     D0
         MOVE    #CAN,0(A0,D0)
         ADDQ    #2,D0
         BSR     Xoutput
         MOVE    #6,U.Select(A5)
         RTS
.60      CMP     #ACK,D0
         BNE.S   .61
         CLR     U.Select(A5)
         BSR     UpdtDspU
.61      RTS
*--------------------------------
DoRD     MOVEQ   #0,D6
         BRA.S   DoD
DoSD     MOVEQ   #1,D6
DoD      MOVE    D.Select(A5),D7
         ADD     D7,D7
         ADD     D6,D7
         ADD     D7,D7
         MOVE    .999(PC,D7),D7
         JMP     .999(PC,D7)
.999     DATA    /.00-.999
         DATA    /.04-.999
         DATA    /.10-.999
         DATA    /.11-.999
         DATA    /.20-.999
         DATA    /.23-.999
         DATA    /.30-.999
         DATA    /.40-.999
         DATA    /.40-.999
         DATA    /.41-.999
         DATA    /.50-.999
         DATA    /.52-.999
         DATA    /.60-.999
         DATA    /.61-.999
.00      TST     D0
         BNE     .04
         LEA     BlkBufR+1(A5),A0
         LEA     D.Name(A5),A1
         CLR     D0
         MOVE.B  (A0),D0
.01      MOVE.B  (A0)+,(A1)+
         DBRA    D0,.01
         LEA     BlkBufR+65(A5),A0
         LEA     D.Type(A5),A1
         MOVEQ   #34-1,D0
.02      MOVE.B  (A0)+,(A1)+
         DBRA    D0,.02
         CLR     D.Volume(A5)
         BSR     InitBlkD
         LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         _Delete
         MOVE    ioResult(A0),D0
         BEQ.S   .03
         CMP     #fnfErr,D0
         BNE     .37
.03      LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         _Create
         MOVE    ioResult(A0),D0
         BNE     .37
         MOVE    #1,D.Select(A5)
.04      RTS
.10      BRA     .36
.11      LEA     BlkBufS(A5),A0
         CLR     D0
         MOVE    #ACK,0(A0,D0)
         ADDQ    #2,D0
         BSR     Xoutput
         TST.L   D.DataLen(A5)
         BEQ     .22
         LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         MOVE.B  #fsWrPerm,ioPermssn(A0)
         LEA     D.OwnBuf(A5),A1
         MOVE.L  A1,ioMisc(A0)
         _Open
         MOVE    ioResult(A0),D0
         BNE     .36
         MOVE    ioRefNum(A0),D.RefNum(A5)
         MOVE    #2,D.Select(A5)
         RTS
.20      TST     D0
         BNE     .35
         MOVE.L  #128,D1
         CMP.L   D.DataLen(A5),D1
         BLS.S   .21
         MOVE.L  D.DataLen(A5),D1
.21      LEA     ParaBlk(A5),A0
         MOVE    D.RefNum(A5),ioRefNum(A0)
         LEA     BlkBufR(A5),A1
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  D1,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Write
         MOVE    ioResult(A0),D0
         BNE     .35
         MOVE.L  ioActCount(A0),D0
         SUB.L   D0,D.DataLen(A5)
         ADDQ    #1,D.Block(A5)
         BSR     DispBlkD
         TST.L   D.DataLen(A5)
         BNE.S   .23
         LEA     ParaBlk(A5),A0
         MOVE    D.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    ioResult(A0),D0
         BNE     .35
.22      TST.L   D.RsrcLen(A5)
         BEQ     .32
         LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         MOVE.B  #fsWrPerm,ioPermssn(A0)
         LEA     D.OwnBuf(A5),A1
         MOVE.L  A1,ioMisc(A0)
         _OpenRF
         MOVE    ioResult(A0),D0
         BNE     .36
         MOVE    ioRefNum(A0),D.RefNum(A5)
         MOVE    #3,D.Select(A5)
.23      RTS
.30      TST     D0
         BNE     .35
         MOVE.L  #128,D1
         CMP.L   D.RsrcLen(A5),D1
         BLS.S   .31
         MOVE.L  D.RsrcLen(A5),D1
.31      LEA     ParaBlk(A5),A0
         MOVE    D.RefNum(A5),ioRefNum(A0)
         LEA     BlkBufR(A5),A1
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  D1,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Write
         MOVE    ioResult(A0),D0
         BNE     .35
         MOVE.L  ioActCount(A0),D0
         SUB.L   D0,D.RsrcLen(A5)
         ADDQ    #1,D.Block(A5)
         BSR     DispBlkD
         TST.L   D.RsrcLen(A5)
         BNE     .40
         LEA     ParaBlk(A5),A0
         MOVE    D.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    ioResult(A0),D0
         BNE     .35
.32      LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         MOVE.L  D.Type(A5),32(A0)
         MOVE.L  D.Creator(A5),36(A0)
         MOVE    D.Flags(A5),40(A0)
         AND     #$F8FE,40(A0)
         CLR.L   42(A0)
         CLR     46(A0)
         MOVE.L  D.FlCrDat(A5),72(A0)
         MOVE.L  D.FlMdDat(A5),76(A0)
         _SetFileInfo
         MOVE    ioResult(A0),D0
         BNE.S   .36
         MOVE.B  D.Locked(A5),D0
         AND.B   #$01,D0
         BEQ.S   .33
         LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         _SetFilLock
         MOVE    ioResult(A0),D0
         BNE.S   .36
.33      LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         _FlushVol
         MOVE    ioResult(A0),D0
         BNE.S   .36
         BRA.S   .51
.35      MOVE    D0,-(SP)
         LEA     ParaBlk(A5),A0
         MOVE    D.RefNum(A5),ioRefNum(A0)
         _Close
         MOVE    (SP)+,D0
.36      MOVE    D0,-(SP)
         LEA     ParaBlk(A5),A0
         LEA     D.Name(A5),A1
         MOVE.L  A1,ioNamePtr(A0)
         MOVE    D.Volume(A5),ioVRefNum(A0)
         CLR.B   ioVersNum(A0)
         _Delete
         MOVE    (SP)+,D0
.37      MOVE    #4,D.Select(A5)
.40      RTS
.41      LEA     BlkBufS(A5),A0
         CLR     D0
         MOVE    #NAK,0(A0,D0)
         ADDQ    #2,D0
         BSR     Xoutput
         MOVE    #5,D.Select(A5)
         RTS
.50      CMP     #CAN,D0
         BNE.S   .52
.51      MOVE    #6,D.Select(A5)
.52      RTS
.60      BRA.S   .37
.61      LEA     BlkBufS(A5),A0
         CLR     D0
         MOVE    #ACK,0(A0,D0)
         ADDQ    #2,D0
         BSR     Xoutput
         CLR     D.Select(A5)
         BSR     UpdtDspD
         RTS
*--------------------------------
UpdtDspU TST     U.Select(A5)
         BNE.S   .0
         MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     U.10(PC)
         _FrameRect
         PEA     U.11(PC)
         MOVE.L  (A5),A0
         PEA     ltGray(A0)
         _FillRect
         RTS
.0       BSR     DispU
         BSR     DispBlkU
         RTS
InitBlkU MOVE.L  U.DataLen(A5),D0
         ADD.L   #127,D0
         AND.L   #$FFFFFF80,D0
         MOVE.L  U.RsrcLen(A5),D1
         ADD.L   #127,D1
         AND.L   #$FFFFFF80,D1
         ADD.L   D1,D0
         LSR.L   #7,D0
         MOVE    D0,U.MaxBlk(A5)
         CLR     U.Block(A5)
DispU    MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     U.10(PC)
         _FrameRect
         PEA     U.11(PC)
         _EraseRect
         MOVE    #009+00*06,-(SP)
         MOVE    #246+00*11,-(SP)
         _MoveTo
         PEA     U.20(PC)
         _DrawString
         PEA     U.Name(A5)
         _DrawString
         MOVE    #009+00*06,-(SP)
         MOVE    #246+01*11,-(SP)
         _MoveTo
         PEA     U.21(PC)
         _DrawString
         MOVE.L  U.DataLen(A5),D0
         ADD.L   U.RsrcLen(A5),D0
         LEA     DeskName(A5),A0
         MOVE    #NumToString,-(SP)
         _Pack7
         MOVE.L  A0,-(SP)
         _DrawString
         PEA     U.22(PC)
         _DrawString
         PEA     U.12(PC)
         _FrameRect
         RTS
DispBlkU MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         LEA     TempRect(A5),A0
         MOVE.L  U.12+topLeft(PC),topLeft(A0)
         MOVE.L  U.12+botRight(PC),botRight(A0)
         MOVE    U.Block(A5),D0
         MULU    #353,D0
         DIVU    U.MaxBlk(A5),D0
         ADD     #136,D0
         MOVE    D0,right(A0)
         MOVE.L  A0,-(SP)
         _FrameRect
         LEA     TempRect(A5),A0
         ADDQ    #1,top(A0)
         ADDQ    #1,left(A0)
         SUBQ    #1,bottom(A0)
         SUBQ    #1,right(A0)
         MOVE.L  A0,-(SP)
         MOVE.L  (A5),A0
         PEA     gray(A0)
         _FillRect
         RTS
U.10     DATA    /234,/004,/262,/494
U.11     DATA    /235,/005,/261,/493
U.12     DATA    /250,/135,/257,/489
U.20     STR     "File: "
U.21     STR     "Size: "
U.22     STR     " bytes"
         ADJST
*--------------------------------
UpdtDspD TST     D.Select(A5)
         BNE.S   .0
         MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     D.10(PC)
         _FrameRect
         PEA     D.11(PC)
         MOVE.L  (A5),A0
         PEA     ltGray(A0)
         _FillRect
         RTS
.0       BSR     DispD
         BSR     DispBlkD
         RTS
InitBlkD MOVE.L  D.DataLen(A5),D0
         ADD.L   #127,D0
         AND.L   #$FFFFFF80,D0
         MOVE.L  D.RsrcLen(A5),D1
         ADD.L   #127,D1
         AND.L   #$FFFFFF80,D1
         ADD.L   D1,D0
         LSR.L   #7,D0
         MOVE    D0,D.MaxBlk(A5)
         CLR     D.Block(A5)
DispD    MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     D.10(PC)
         _FrameRect
         PEA     D.11(PC)
         _EraseRect
         MOVE    #009+00*06,-(SP)
         MOVE    #278+00*11,-(SP)
         _MoveTo
         PEA     D.20(PC)
         _DrawString
         PEA     D.Name(A5)
         _DrawString
         MOVE    #009+00*06,-(SP)
         MOVE    #278+01*11,-(SP)
         _MoveTo
         PEA     D.21(PC)
         _DrawString
         MOVE.L  D.DataLen(A5),D0
         ADD.L   D.RsrcLen(A5),D0
         LEA     DeskName(A5),A0
         MOVE    #NumToString,-(SP)
         _Pack7
         MOVE.L  A0,-(SP)
         _DrawString
         PEA     D.22(PC)
         _DrawString
         PEA     D.12(PC)
         _FrameRect
         RTS
DispBlkD MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         LEA     TempRect(A5),A0
         MOVE.L  D.12+topLeft(PC),topLeft(A0)
         MOVE.L  D.12+botRight(PC),botRight(A0)
         MOVE    D.Block(A5),D0
         MULU    #353,D0
         DIVU    D.MaxBlk(A5),D0
         ADD     #136,D0
         MOVE    D0,right(A0)
         MOVE.L  A0,-(SP)
         _FrameRect
         LEA     TempRect(A5),A0
         ADDQ    #1,top(A0)
         ADDQ    #1,left(A0)
         SUBQ    #1,bottom(A0)
         SUBQ    #1,right(A0)
         MOVE.L  A0,-(SP)
         MOVE.L  (A5),A0
         PEA     gray(A0)
         _FillRect
         RTS
D.10     DATA    /266,/004,/294,/494
D.11     DATA    /267,/005,/293,/493
D.12     DATA    /282,/135,/289,/489
D.20     STR     "File: "
D.21     STR     "Size: "
D.22     STR     " bytes"
         ADJST
*--------------------------------
DspScrn  MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     .10(PC)
         _FrameRect
         BSR     DspLogo
         BSR     DspI
         TST.B   CarOn(A5)
         BEQ.S   .0
         BSR     InverCar
.0       RTS
.10      DATA    /004,/004,/230,/494
*--------------------------------
Cls      MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     .0(PC)
         _EraseRect
         RTS
.0       DATA    /007,/009,/216,/489
*--------------------------------
DspS     MOVE.L  A0,-(SP)
         MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         CLR.L   -(SP)
         _NewRgn
         MOVE.L  (SP),A0
         PEA     .0(PC)
         MOVE    #+00,-(SP)
         MOVE    #-11,-(SP)
         MOVE.L  A0,-(SP)
         _ScrollRect
         _DisposRgn
         MOVE    #09+00*06,-(SP)
         MOVE    #16+18*11,-(SP)
         _MoveTo
         _DrawString
         RTS
.0       DATA    /007,/009,/216,/489
*--------------------------------
DspI     MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     .0(PC)
         _ClipRect
         MOVE    #srcCopy,-(SP)
         _TextMode
         MOVE    #09+00*06,-(SP)
         MOVE    #16+19*11,-(SP)
         _MoveTo
         PEA     InpBuf(A5)
         CLR     -(SP)
         MOVE    #80,-(SP)
         _DrawText
         MOVE    #srcOr,-(SP)
         _TextMode
         PEA     wClip(PC)
         _ClipRect
         RTS
.0       DATA    /216,/009,/227,/489
*--------------------------------
OnLine   ST      LineFlag(A5)
         BSR     OnInp
         MOVE.L  NameQueue(A5),NameHandle(A5)
         RTS
OfLine   SF      LineFlag(A5)
         BSR     OffInp
         MOVE    #-1,D0
         BSR     DoRD
         CLR     D.Select(A5)
         BSR     UpdtDspD
         MOVE    #-1,D0
         BSR     DoRU
         CLR     U.Select(A5)
         BSR     UpdtDspU
         CLR.L   NameHandle(A5)
         RTS
*--------------------------------
OnInp    ST      InpOn(A5)
         TST.B   CarAct(A5)
         BEQ.S   .0
         BSR     OnCar
.0       RTS
OffInp   SF      InpOn(A5)
         BSR     OffCar
         RTS
*--------------------------------
IdleCar  TST.B   InpOn(A5)
         BEQ.S   .0
         TST.B   CarAct(A5)
         BEQ.S   .0
         MOVE.L  Ticks,A0
         CMP.L   CarTime(A5),A0
         BLO.S   .0
         ADD.L   CaretTime,A0
         MOVE.L  A0,CarTime(A5)
         BSR     InverCar
         NOT.B   CarOn(A5)
.0       RTS
ActCar   ST      CarAct(A5)
         TST.B   InpOn(A5)
         BEQ.S   .0
         BSR     OnCar
.0       RTS
DeActCar SF      CarAct(A5)
         BSR     OffCar
         RTS
OnCar    TST.B   CarOn(A5)
         BNE.S   .0
         BSR     InverCar
         ST      CarOn(A5)
.0       RTS
OffCar   TST.B   CarOn(A5)
         BEQ.S   .0
         BSR     InverCar
         SF      CarOn(A5)
.0       RTS
InverCar MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         LEA     TempRect(A5),A0
         MOVE    #216,top(A0)
         MOVE    #227,bottom(A0)
         MOVE    CarPos(A5),D0
         MULU    #06,D0
         ADD     #09,D0
         MOVE    D0,right(A0)
         SUBQ    #1,D0
         MOVE    D0,left(A0)
         MOVE.L  A0,-(SP)
         _InverRect
         RTS
*--------------------------------
wOpen    CLR.L   -(SP)
         PEA     wStorage(A5)
         PEA     wBounds(PC)
         PEA     wTitle(PC)
         ST      -(SP)
         MOVE    #plainDBox,-(SP)
         MOVE.L  MinusOne,-(SP)
         SF      -(SP)
         CLR.L   -(SP)
         _NewWindow
         MOVE.L  (SP)+,TheWindow(A5)
         MOVE.L  TheWindow(A5),-(SP)
         _SetPort
         PEA     wClip(PC)
         _ClipRect
         MOVE    #monaco,-(SP)
         _TextFont
         MOVE    #9,-(SP)
         _TextSize
         MOVE    #srcOr,-(SP)
         _TextMode
         RTS
wClose   MOVE.L  TheWindow(A5),-(SP)
         _CloseWindow
         RTS
wClip    DATA    /004,/004,/294,/494
wBounds  DATA    /028,/007,/326,/505
wTitle   STR     ""
         ADJST
*--------------------------------
LoadCNFG CLR.L   -(SP)
         MOVE.L  #$434E4647,-(SP)        ;"CNFG"
         MOVE    #128,-(SP)
         _GetResource
         MOVE.L  (SP)+,D0
         BEQ.S   .0
         MOVE.L  D0,A0
         MOVE.L  (A0),A0
         MOVE    (A0)+,sPort(A5)
         MOVE    (A0)+,sBaud(A5)
         MOVE    (A0)+,sMode(A5)
         LEA     sInit(A5),A1
         BSR.S   .10
         LEA     sDial(A5),A1
         BSR.S   .10
         SF      RsrcChanged(A5)
.0       RTS
.10      CLR     D0
         MOVE.B  (A0),D0
.11      MOVE.B  (A0)+,(A1)+
         DBRA    D0,.11
         RTS
*--------------------------------
SaveCNFG LINK    A6,#-518
         TST.B   RsrcChanged(A5)
         BEQ.S   .0
         CLR.L   -(SP)
         MOVE.L  #$434E4647,-(SP)        ;"CNFG"
         MOVE    #128,-(SP)
         _GetResource
         MOVE.L  (SP)+,D0
         BEQ.S   .0
         MOVE.L  D0,A1
         LEA     -518(A6),A0
         MOVE.L  A0,A3
         MOVE    sPort(A5),(A3)+
         MOVE    sBaud(A5),(A3)+
         MOVE    sMode(A5),(A3)+
         LEA     sInit(A5),A2
         BSR.S   .10
         LEA     sDial(A5),A2
         BSR.S   .10
         MOVE.L  A3,D0
         SUB.L   A0,D0
         _PtrToXHand
         BNE.S   .0
         MOVE.L  A0,-(SP)
         _ChangedResource
.0       UNLK    A6
         RTS
.10      CLR     D0
         MOVE.B  (A2),D0
.11      MOVE.B  (A2)+,(A3)+
         DBRA    D0,.11
         RTS
*--------------------------------
NameInit CLR.L   NameQueue(A5)
.0       BSR     ArrowCur
         CLR.L   -(SP)
         MOVE    #getDlgID,-(SP)
         BSR     CenterSF
         PEA     .10(PC)
         CLR.L   -(SP)
         MOVE    #-1,-(SP)
         CLR.L   -(SP)
         CLR.L   -(SP)
         PEA     SFReply(A5)
         MOVE    #sfGetFile,-(SP)
         _Pack3
         BSR     WatchCur
         TST.B   SFReply+rGood(A5)
         BEQ.S   .4
         CLR.L   D0
         MOVE.B  SFReply+rName(A5),D0
         ADD     #4+2+2+1,D0
         _NewHandle
         BNE.S   .4
         LEA     NameQueue(A5),A1
.1       MOVE.L  (A1),D0
         BEQ.S   .2
         MOVE.L  D0,A1
         MOVE.L  (A1),A1
         BRA.S   .1
.2       MOVE.L  A0,(A1)
         MOVE.L  (A0),A0
         CLR.L   (A0)
         MOVE    SFReply+rVolume(A5),4(A0)
         MOVE    SFReply+rVersion(A5),6(A0)
         LEA     8(A0),A1
         LEA     SFReply+rName(A5),A0
         CLR     D0
         MOVE.B  (A0),D0
.3       MOVE.B  (A0)+,(A1)+
         DBRA    D0,.3
         BRA.S   .0
.4       RTS
.10      STR     ""
         ADJST
*--------------------------------
GetName  MOVE.L  NameHandle(A5),D0
         BEQ.S   .1
         MOVE.L  D0,A0
         MOVE.L  (A0),A0
         MOVE.L  (A0),NameHandle(A5)
         MOVE    4(A0),U.Volume(A5)
         LEA     8(A0),A0
         LEA     U.Name(A5),A1
         CLR     D0
         MOVE.B  (A0),D0
.0       MOVE.B  (A0)+,(A1)+
         DBRA    D0,.0
.1       TST     D0
         RTS
*--------------------------------
* PROCEDURE CenterAlert (alertID: INTEGER);
*--------------------------------
CenterAlert
         LINK    A6,#0
         CLR.L   -(SP)
         MOVE.L  #$414C5254,-(SP)        ;"ALRT"
         MOVE    8(A6),-(SP)
         _GetResource
         MOVE.L  (SP)+,D0
         BEQ.S   .2
         MOVE.L  D0,A1
         MOVE.L  (A1),A1
         MOVE.L  GrafGlobals(A5),A0
         TST     ROM85
         BMI.S   .0
         MOVE    MBarHeight,D0
         BNE.S   .1
.0       MOVEQ   #20,D0
.1       ADD     screenBits+bounds+top(A0),D0
         SUB     aBounds+top(A1),D0
         ASL     #1,D0
         ADD     screenBits+bounds+bottom(A0),D0
         SUB     aBounds+bottom(A1),D0
         EXT.L   D0
         DIVS    #3,D0
         MOVE    screenBits+bounds+left(A0),D1
         ADD     screenBits+bounds+right(A0),D1
         SUB     aBounds+left(A1),D1
         SUB     aBounds+right(A1),D1
         ASR     #1,D1
         ADD     D0,(A1)+
         ADD     D1,(A1)+
         ADD     D0,(A1)+
         ADD     D1,(A1)+
.2       UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #2,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE CenterDialog (dialogID: INTEGER);
*--------------------------------
CenterDialog
         LINK    A6,#0
         CLR.L   -(SP)
         MOVE.L  #$444C4F47,-(SP)        ;"DLOG"
         MOVE    8(A6),-(SP)
         _GetResource
         MOVE.L  (SP)+,D0
         BEQ.S   .2
         MOVE.L  D0,A1
         MOVE.L  (A1),A1
         MOVE.L  GrafGlobals(A5),A0
         TST     ROM85
         BMI.S   .0
         MOVE    MBarHeight,D0
         BNE.S   .1
.0       MOVEQ   #20,D0
.1       ADD     screenBits+bounds+top(A0),D0
         SUB     dBounds+top(A1),D0
         ASL     #1,D0
         ADD     screenBits+bounds+bottom(A0),D0
         SUB     dBounds+bottom(A1),D0
         EXT.L   D0
         DIVS    #3,D0
         MOVE    screenBits+bounds+left(A0),D1
         ADD     screenBits+bounds+right(A0),D1
         SUB     dBounds+left(A1),D1
         SUB     dBounds+right(A1),D1
         ASR     #1,D1
         ADD     D0,(A1)+
         ADD     D1,(A1)+
         ADD     D0,(A1)+
         ADD     D1,(A1)+
.2       UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #2,A7
         JMP     (A0)
*--------------------------------
* FUNCTION CenterSF (dialogID: INTEGER) : LONGINT;
*--------------------------------
CenterSF LINK    A6,#0
         CLR.L   10(A6)
         CLR.L   -(SP)
         MOVE.L  #$444C4F47,-(SP)        ;"DLOG"
         MOVE    8(A6),-(SP)
         _GetResource
         MOVE.L  (SP)+,D0
         BEQ.S   .2
         MOVE.L  D0,A1
         MOVE.L  (A1),A1
         MOVE.L  GrafGlobals(A5),A0
         TST     ROM85
         BMI.S   .0
         MOVE    MBarHeight,D0
         BNE.S   .1
.0       MOVEQ   #20,D0
.1       ADD     screenBits+bounds+top(A0),D0
         ADD     screenBits+bounds+bottom(A0),D0
         SUB     dBounds+top(A1),D0
         SUB     dBounds+bottom(A1),D0
         ASR     #1,D0
         SWAP    D0
         MOVE    screenBits+bounds+left(A0),D0
         ADD     screenBits+bounds+right(A0),D0
         SUB     dBounds+left(A1),D0
         SUB     dBounds+right(A1),D0
         ASR     #1,D0
         MOVE.L  D0,10(A6)
.2       UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #2,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE SetValue (theDialog: DialogPtr; itemNo: INTEGER;
*                     theValue: INTEGER);
*--------------------------------
SetValue
         LINK    A6,#-14
         MOVE.L  12(A6),-(SP)
         MOVE    10(A6),-(SP)
         PEA     -2(A6)
         PEA     -6(A6)
         PEA     -14(A6)
         _GetDItem
         MOVE.L  -6(A6),-(SP)
         MOVE    8(A6),-(SP)
         _SetCtlValue
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #8,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE GetText (theDialog: DialogPtr; itemNo: INTEGER;
*                    VAR text: Str255);
*--------------------------------
GetText  LINK    A6,#-14
         MOVE.L  14(A6),-(SP)
         MOVE    12(A6),-(SP)
         PEA     -2(A6)
         PEA     -6(A6)
         PEA     -14(A6)
         _GetDItem
         MOVE.L  -6(A6),-(SP)
         MOVE.L  8(A6),-(SP)
         _GetIText
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #10,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE SetText (theDialog: DialogPtr; itemNo: INTEGER;
*                    text: Str255);
*--------------------------------
SetText  LINK    A6,#-14
         MOVE.L  14(A6),-(SP)
         MOVE    12(A6),-(SP)
         PEA     -2(A6)
         PEA     -6(A6)
         PEA     -14(A6)
         _GetDItem
         MOVE.L  -6(A6),-(SP)
         MOVE.L  8(A6),-(SP)
         _SetIText
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #10,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE UserItem (theDialog: DialogPtr; itemNo: INTEGER);
*--------------------------------
UserItem LINK    A6,#-14
         MOVE.L  10(A6),-(SP)
         MOVE    8(A6),-(SP)
         PEA     -2(A6)
         PEA     -6(A6)
         PEA     -14(A6)
         _GetDItem
         MOVE.L  10(A6),-(SP)
         MOVE    8(A6),-(SP)
         MOVE    -2(A6),-(SP)
         PEA     MyItem(PC)
         PEA     -14(A6)
         _SetDItem
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #6,A7
         JMP     (A0)
*--------------------------------
* PROCEDURE MyItem (theDialog: DialogPtr; itemNo: INTEGER);
*--------------------------------
MyItem   LINK    A6,#-32
         MOVE.L  10(A6),-(SP)
         MOVE    #1,-(SP)
         PEA     -2(A6)
         PEA     -6(A6)
         PEA     -14(A6)
         _GetDItem
         PEA     -32(A6)
         _GetPenState
         MOVE    #3,-(SP)
         MOVE    #3,-(SP)
         _PenSize
         PEA     -14(A6)
         MOVE    #-4,-(SP)
         MOVE    #-4,-(SP)
         _InsetRect
         PEA     -14(A6)
         MOVE    #16,-(SP)
         MOVE    #16,-(SP)
         _FrameRoundRect
         PEA     -32(A6)
         _SetPenState
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #6,A7
         JMP     (A0)
*--------------------------------
SetUpMenus
         CLR.L   -(SP)
         MOVE    #MenuBarID,-(SP)
         _GetNewMBar
         MOVE.L  (SP),-(SP)
         _SetMenuBar
         MOVE.L  (SP)+,A0
         _DisposHandle
         CLR.L   -(SP)
         MOVE    #AppleID,-(SP)
         _GetMHandle
         MOVE.L  #$44525652,-(SP)        ;"DRVR"
         _AddResMenu
         _DrawMenuBar
         RTS
*--------------------------------
UpdAMenu TST.B   ModemFlag(A5)
         BEQ.S   .0
         TST.B   LineFlag(A5)
         BNE.S   .1
.0       CLR.L   -(SP)
         MOVE    #AppleID,-(SP)
         _GetMHandle
         MOVE    #AboutItem,-(SP)
         _EnableItem
         RTS
.1       CLR.L   -(SP)
         MOVE    #AppleID,-(SP)
         _GetMHandle
         MOVE    #AboutItem,-(SP)
         _DisableItem
         RTS
*--------------------------------
UpdFMenu TST.B   ModemFlag(A5)
         BNE.S   .0
         CLR.L   -(SP)
         MOVE    #FileID,-(SP)
         _GetMHandle
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE    #DialItem,-(SP)
         _DisableItem
         MOVE    #HangupItem,-(SP)
         _DisableItem
         MOVE    #SettingsItem,-(SP)
         _EnableItem
         RTS
.0       TST.B   LineFlag(A5)
         BNE.S   .1
         CLR.L   -(SP)
         MOVE    #FileID,-(SP)
         _GetMHandle
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE    #DialItem,-(SP)
         _EnableItem
         MOVE    #HangupItem,-(SP)
         _DisableItem
         MOVE    #SettingsItem,-(SP)
         _EnableItem
         RTS
.1       CLR.L   -(SP)
         MOVE    #FileID,-(SP)
         _GetMHandle
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE    #DialItem,-(SP)
         _DisableItem
         MOVE    #HangupItem,-(SP)
         _EnableItem
         MOVE    #SettingsItem,-(SP)
         _DisableItem
         RTS
*--------------------------------
UpdEMenu CLR.L   -(SP)
         _FrontWindow
         MOVE.L  (SP)+,D0
         BEQ.S   .0
         MOVE.L  D0,A0
         MOVE    windowKind(A0),D0
         BMI.S   .1
.0       CLR.L   -(SP)
         MOVE    #EditID,-(SP)
         _GetMHandle
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE    #UndoItem,-(SP)
         _DisableItem
         MOVE    #CutItem,-(SP)
         _DisableItem
         MOVE    #CopyItem,-(SP)
         _DisableItem
         MOVE    #PasteItem,-(SP)
         _DisableItem
         MOVE    #ClearItem,-(SP)
         _DisableItem
         RTS
.1       CLR.L   -(SP)
         MOVE    #EditID,-(SP)
         _GetMHandle
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE.L  (SP),-(SP)
         MOVE    #UndoItem,-(SP)
         _EnableItem
         MOVE    #CutItem,-(SP)
         _EnableItem
         MOVE    #CopyItem,-(SP)
         _EnableItem
         MOVE    #PasteItem,-(SP)
         _EnableItem
         MOVE    #ClearItem,-(SP)
         _EnableItem
         RTS
*--------------------------------
FixCursor
         CLR.L   -(SP)
         _FrontWindow
         MOVE.L  (SP)+,D0
         BEQ.S   .0
         CMP.L   TheWindow(A5),D0
         BNE.S   .1
         TST.B   InpOn(A5)
         BEQ.S   .0
         TST.B   CarAct(A5)
         BEQ.S   .0
         CLR.B   -(SP)
         CLR.L   -(SP)
         MOVE.L  A7,-(SP)
         _GetMouse
         PEA     .10(PC)
         _PtInRect
         TST.B   (SP)+
         BEQ.S   .0
         BSR     IBeamCur
         RTS
.0       BSR     ArrowCur
.1       RTS
.10      DATA    /216,/006,/227,/492
*--------------------------------
SetUpCursors
         CLR.L   -(SP)
         MOVE    #IBeamCursor,-(SP)
         _GetCursor
         MOVE.L  (SP)+,IBeam(A5)
         CLR.L   -(SP)
         MOVE    #WatchCursor,-(SP)
         _GetCursor
         MOVE.L  (SP)+,Watch(A5)
         _InitCursor
         RTS
ArrowCur MOVE.L  (A5),A0
         PEA     arrow(A0)
         _SetCursor
         RTS
IBeamCur MOVE.L  IBeam(A5),A0
         MOVE.L  (A0),-(SP)
         _SetCursor
         RTS
WatchCur MOVE.L  Watch(A5),A0
         MOVE.L  (A0),-(SP)
         _SetCursor
         RTS
*--------------------------------
VarInit  LEA     InpBuf(A5),A0
         MOVEQ   #80/4-1,D1
         MOVE.L  #$20202020,D0
.0       MOVE.L  D0,(A0)+
         DBRA    D1,.0
         CLR     CarPos(A5)
         CLR.L   CarTime(A5)
         SF      CarAct(A5)
         SF      CarOn(A5)
         SF      InpOn(A5)
         CLR     U.Select(A5)
         CLR     D.Select(A5)
         RTS
*--------------------------------
DspLogo  TST.B   LogoFlg(A5)
         BNE.S   .0
         PEA     Blk1(PC)
         MOVE.L  #Blk1Len,-(SP)
         PEA     Blk1Rect(PC)
         MOVE    #teJustCenter,-(SP)
         _TextBox
         PEA     Blk2(PC)
         MOVE.L  #Blk2Len,-(SP)
         PEA     Blk2Rect(PC)
         MOVE    #teJustLeft,-(SP)
         _TextBox
         PEA     Blk3(PC)
         MOVE.L  #Blk3Len,-(SP)
         PEA     Blk3Rect(PC)
         MOVE    #teJustCenter,-(SP)
         _TextBox
         ST      LogoFlg(A5)
.0       RTS
*--------------------------------
Blk1Rect DATA    /018,/008,/051,/489
Blk2Rect DATA    /062,/008,/150,/489
Blk3Rect DATA    /161,/008,/205,/489
Blk1     ASC     "Multichannel Communications System"
         HEX     0D
         ASC     "by"
         HEX     0D
         ASC     "Yves Lempereur"
Blk1Len  EQU     *-Blk1
Blk2     ASC     "This version of MCS is offered to you as shareware. "
         ASC     "Although a copyrighted program, you are encouraged "
         ASC     "to offer a copy of it to anyone who wants it. You "
         ASC     "may not modify or sell this program without express "
         ASC     "written permission of the author."
         HEX     0D0D
         ASC     "If you decide to keep and use this program, please "
         ASC     "send $15.00 to the author. Include your name and "
         ASC     "address to be advised of future developments. Your "
         ASC     "support will assure other high quality shareware "
         ASC     "utilities. Thank you."
Blk2Len  EQU     *-Blk2
Blk3     ASC     "Yves Lempereur"
         HEX     0D
         ASC     "5311-B Derry Avenue"
         HEX     0D
         ASC     "Agoura Hills, CA 91301"
         HEX     0D
         ASC     "(818) 991-6540"
Blk3Len  EQU     *-Blk3
         ADJST
*--------------------------------
DataInit CLR.B   sDial(A5)
         CLR.B   sInit(A5)
         MOVE    #2,sBaud(A5)
         MOVE    #1,sMode(A5)
         MOVE    #0,sPort(A5)
         ST      RsrcChanged(A5)
         SF      LineFlag(A5)
         SF      ModemFlag(A5)
         SF      Quitting(A5)
         SF      Finished(A5)
         SF      LogoFlg(A5)
         RTS
*--------------------------------
MxApplZone
         TST     ROM85
         BPL.S   .2
         MOVE.L  ApplLimit,A0
         LEA     HeapEnd,A1
         MOVE.L  A0,D0
         SUB.L   (A1),D0
         MOVEQ   #12,D2
         CMP.L   D2,D0
         BLO.S   .1
         MOVE.L  (A1),A1
         MOVE.L  A0,HeapEnd
         MOVE.L  D0,(A1)
         CLR.B   (A1)
         MOVE.L  ApplZone,A1
         MOVE.L  A0,(A1)
         MOVE.L  D2,(A0)
         ADD.L   D0,12(A1)
.1       RTS
.2       _MaxApplZone
         RTS
*--------------------------------
Mopen    MOVEM.L D3-D7/A2-A4,-(SP)
         TST.B   ModemFlag(A5)
         BNE.S   .0
         BSR     T_Open
         SEQ     ModemFlag(A5)
.0       MOVEM.L (SP)+,D3-D7/A2-A4
         RTS
*--------------------------------
Mreset   MOVEM.L D3-D7/A2-A4,-(SP)
         TST.B   ModemFlag(A5)
         BEQ.S   .0
         BSR     T_Reset
         BEQ.S   .0
         BSR     T_Close
         SF      ModemFlag(A5)
.0       MOVEM.L (SP)+,D3-D7/A2-A4
         RTS
*--------------------------------
Mclose   MOVEM.L D3-D7/A2-A4,-(SP)
         TST.B   ModemFlag(A5)
         BEQ.S   .0
         BSR     T_Close
         SF      ModemFlag(A5)
.0       MOVEM.L (SP)+,D3-D7/A2-A4
         RTS
*++++++++++++++++++++++++++++++++
T_Open   MOVE    sPort(A5),D0
         BSR     Xopen
         BSR     Reset
         BEQ.S   .0
         BSR     Xclose
         MOVEQ   #-1,D0
.0       RTS
*--------------------------------
T_Close  BSR     Reset
         BSR     Xclose
         MOVEQ   #0,D0
         RTS
*--------------------------------
T_Reset  BRA     Set
*--------------------------------
T_Call   BSR     Dial
         BLE.S   .1
         CMP     #1,D0
         BNE.S   .0
         BSR     HangUp
.0       BSR     Set
         MOVEQ   #-1,D0
.1       RTS
*--------------------------------
T_Listen BSR     Answer
         BLE.S   .1
         CMP     #1,D0
         BNE.S   .0
         BSR     HangUp
.0       BSR     Set
         MOVEQ   #-1,D0
.1       RTS
*--------------------------------
T_Hangup BSR     HangUp
         BSR     Set
         MOVEQ   #0,D0
         RTS
*--------------------------------
T_Status BRA     Xstatus
*--------------------------------
T_Receive BRA    Xinput
*--------------------------------
T_Send   BRA     Xoutput
*================================
Reset    CLR.L   ShftReg(A5)
         BSR     Xreset
         MOVE    sBaud(A5),D0
         BSR     Xset
         BSR     Wait05
         LEA     MDM1(PC),A0
         BSR     PutStr
         LEA     MDM2(PC),A0
         BSR     PutStr
         MOVEQ   #CR,D0
         BSR     PutChr
         MOVE.L  #2*60,D4
         ADD.L   Ticks,D4
.0       CLR     D5
.1       CMP.L   Ticks,D4
         BMI.S   .3
         BSR     Xstachr
         TST.L   D0
         BEQ.S   .1
         BSR     GetChr
         CMP.B   #CR,D0
         BEQ.S   .2
         LSL     #8,D5
         MOVE.B  D0,D5
         BRA.S   .1
.2       CMP     #$4F4B,D5       ;"OK"
         BNE.S   .0
         MOVEQ   #0,D0
         RTS
.3       MOVEQ   #-1,D0
         RTS
*--------------------------------
Set      CLR.L   ShftReg(A5)
         BSR     Xreset
         MOVE    sBaud(A5),D0
         BSR     Xset
         BSR     Wait05
         LEA     MDM1(PC),A0
         BSR     PutStr
         LEA     sInit(A5),A0
         BSR     PutStr
         LEA     MDM7(PC),A0
         BSR     PutStr
         MOVEQ   #CR,D0
         BSR     PutChr
         MOVE.L  #2*60,D4
         ADD.L   Ticks,D4
.0       CLR     D5
.1       CMP.L   Ticks,D4
         BMI.S   .3
         BSR     Xstachr
         TST.L   D0
         BEQ.S   .1
         BSR     GetChr
         CMP.B   #CR,D0
         BEQ.S   .2
         LSL     #8,D5
         MOVE.B  D0,D5
         BRA.S   .1
.2       CMP     #$4F4B,D5       ;"OK"
         BNE.S   .0
         MOVEQ   #0,D0
         RTS
.3       MOVEQ   #-1,D0
         RTS
*--------------------------------
Answer   BSR     Xstachr
         TST.L   D0
         BNE.S   .0
         MOVEQ   #-1,D0
         BRA     .7
.0       BSR     GetChr
         CMP.B   #CR,D0
         BEQ.S   .1
         MOVE.L  ShftReg(A5),D1
         LSL.L   #8,D1
         MOVE.B  D0,D1
         MOVE.L  D1,ShftReg(A5)
         BRA.S   Answer
.1       MOVE.L  ShftReg(A5),D1
         MOVE    #3,D0
         CMP.L   #$32343030,D1   ;"2400"
         BEQ.S   .2
         MOVE    #2,D0
         CMP.L   #$31323030,D1   ;"1200"
         BEQ.S   .2
         MOVE    #1,D0
         CMP.L   #$30363030,D1   ;"0600"
         BEQ.S   .2
         MOVE    #0,D0
         CMP.L   #$4E454354,D1   ;"NECT"
         BEQ.S   .2
         CLR.L   ShftReg(A5)
         BRA.S   Answer
.2       MOVE    D0,sRate(A5)
         BSR     Xset
         LEA     .10(PC),A0
         BSR     DspS
         BSR     Quiet
         BSR     XputDCD
         BSR     Wait30
         LEA     .11(PC),A0
         BSR     PutStr
         MOVE.L  #4*60,D4
         ADD.L   Ticks,D4
.3       CMP.L   Ticks,D4
         BPL.S   .4
         LEA     .12(PC),A0
         BSR     DspS
         MOVEQ   #1,D0
         BRA.S   .7
.4       BSR     XgetDCD
         BEQ.S   .5
         LEA     .13(PC),A0
         BSR     DspS
         MOVEQ   #2,D0
         BRA.S   .7
.5       BSR     Xstachr
         TST.L   D0
         BEQ.S   .3
         BSR     GetChr
         CMP.B   #CR,D0
         BNE.S   .6
         LEA     .12(PC),A0
         BSR     DspS
         MOVEQ   #1,D0
         BRA.S   .7
.6       CMP.B   #ESC,D0
         BNE.S   .3
         LEA     .14(PC),A0
         BSR     DspS
         MOVEQ   #0,D0
.7       RTS
.10      STR     "CONNECT"
.11      DATA    #48,#ESC,#ESC,#ESC,#ESC,#CR,#LF,#FF
         ASC     "You must use MCS to call this system..."
         DATA    #CR,#LF
.12      STR     "NO LOCK"
.13      STR     "NO CARRIER"
.14      STR     "LOCK"
         ADJST
*--------------------------------
Dial     CLR.L   ShftReg(A5)
         BSR     Xreset
         MOVE    sBaud(A5),D0
         BSR     Xset
         LEA     .20(PC),A0
         BSR     DspS
         BSR     Wait05
         LEA     MDM1(PC),A0
         BSR     PutStr
         LEA     MDM3(PC),A0
         BSR     PutStr
         TST     sMode(A5)
         BNE.S   .0
         LEA     MDM5(PC),A0
         BRA.S   .1
.0       LEA     MDM6(PC),A0
.1       BSR     PutStr
         LEA     sDial(A5),A0
         BSR     PutStr
         MOVEQ   #CR,D0
         BSR     PutChr
         MOVE.L  #1*60*60,D4
         ADD.L   Ticks,D4
.2       CLR.L   D5
.3       CMP.L   Ticks,D4
         BPL.S   .4
         LEA     .21(PC),A0
         BSR     DspS
         MOVEQ   #-1,D0
         BRA     .12
.4       BSR     Xstachr
         TST.L   D0
         BEQ.S   .3
         BSR     GetChr
         CMP.B   #CR,D0
         BEQ.S   .5
         LSL.L   #8,D5
         MOVE.B  D0,D5
         BRA.S   .3
.5       CMP.L   #$52524F52,D5   ;"RROR"
         BEQ.S   .6
         CMP.L   #$53574552,D5   ;"SWER"
         BEQ.S   .6
         CMP.L   #$544F4E45,D5   ;"TONE"
         BEQ.S   .6
         CMP.L   #$52494552,D5   ;"RIER"
         BEQ.S   .6
         CMP.L   #$42555359,D5   ;"BUSY"
         BNE.S   .7
.6       LEA     .22(PC),A0
         BSR     DspS
         MOVEQ   #2,D0
         BRA     .12
.7       MOVE    #3,D0
         CMP.L   #$32343030,D5   ;"2400"
         BEQ.S   .8
         MOVE    #2,D0
         CMP.L   #$31323030,D5   ;"1200"
         BEQ.S   .8
         MOVE    #1,D0
         CMP.L   #$30363030,D5   ;"0600"
         BEQ.S   .8
         MOVE    #0,D0
         CMP.L   #$4E454354,D5   ;"NECT"
         BNE     .2
.8       MOVE    D0,sRate(A5)
         BSR     Xset
         LEA     .23(PC),A0
         BSR     DspS
         BSR     Wait10
         BSR     XputDCD
         MOVE.L  #10*60,D4
         ADD.L   Ticks,D4
.9       CMP.L   Ticks,D4
         BPL.S   .10
         LEA     .24(PC),A0
         BSR     DspS
         MOVEQ   #1,D0
         BRA.S   .12
.10      BSR     XgetDCD
         BEQ.S   .11
         LEA     .25(PC),A0
         BSR     DspS
         MOVEQ   #2,D0
         BRA.S   .12
.11      BSR     Xstachr
         TST.L   D0
         BEQ.S   .9
         BSR     GetChr
         CMP.B   #ESC,D0
         BNE.S   .9
         LEA     .26(PC),A0
         BSR     DspS
         LEA     .27(PC),A0
         BSR     PutStr
         MOVEQ   #0,D0
.12      RTS
.20      STR     "DIALING…"
.21      STR     "NO MODEM"
.22      STR     "NO CONNECT"
.23      STR     "CONNECT"
.24      STR     "NO LOCK"
.25      STR     "NO CARRIER"
.26      STR     "LOCK"
.27      DATA    #4,#ESC,#ESC,#ESC,#ESC
         ADJST
*--------------------------------
HangUp   CLR.L   ShftReg(A5)
         LEA     .10(PC),A0
         BSR     DspS
         BSR     Wait15
         LEA     MDM0(PC),A0
         BSR     PutStr
         BSR     Wait10
         BSR     Quiet
         LEA     MDM1(PC),A0
         BSR     PutStr
         LEA     MDM4(PC),A0
         BSR     PutStr
         MOVEQ   #CR,D0
         BSR     PutChr
         MOVE.L  #2*60,D4
         ADD.L   Ticks,D4
.0       CLR     D5
.1       CMP.L   Ticks,D4
         BMI.S   .3
         BSR     Xstachr
         TST.L   D0
         BEQ.S   .1
         BSR     GetChr
         CMP.B   #CR,D0
         BEQ.S   .2
         LSL     #8,D5
         MOVE.B  D0,D5
         BRA.S   .1
.2       CMP     #$4F4B,D5       ;"OK"
         BNE.S   .0
         MOVEQ   #0,D0
         RTS
.3       MOVEQ   #-1,D0
         RTS
.10      STR     "DISCONNECT"
         ADJST
*--------------------------------
Wait30   MOVE    #30*6,A0
         BRA.S   Wait
Wait20   MOVE    #20*6,A0
         BRA.S   Wait
Wait15   MOVE    #15*6,A0
         BRA.S   Wait
Wait10   MOVE    #10*6,A0
         BRA.S   Wait
Wait05   MOVE    #5*6,A0
Wait     ADD.L   Ticks,A0
.0       CMP.L   Ticks,A0
         BPL.S   .0
         RTS
Quiet    MOVE.L  #1*60,D4
         ADD.L   Ticks,D4
.0       CMP.L   Ticks,D4
         BMI.S   .1
         BSR     Xstachr
         TST.L   D0
         BEQ.S   .0
         BSR     GetChr
         BRA.S   Quiet
.1       RTS
*--------------------------------
GetChr   MOVE.B  D0,-(SP)
         MOVE.L  A7,A0
         MOVEQ   #1,D0
         BSR     Xgetchr
         MOVE.B  (SP)+,D0
         RTS
PutChr   MOVE.B  D0,-(SP)
         MOVE.L  A7,A0
         MOVEQ   #1,D0
         BSR     Xputchr
         MOVE.B  (SP)+,D0
         RTS
PutStr   CLR.L   D0
         MOVE.B  (A0)+,D0
         BSR     Xputchr
         RTS
*--------------------------------
MDM0     STR     "+++"
MDM1     STR     "AT"
MDM2     STR     "Z"
MDM3     STR     "D"
MDM4     STR     "H"
MDM5     STR     "P"
MDM6     STR     "T"
MDM7     STR     "S0=1"
         ADJST
*++++++++++++++++++++++++++++++++
*      D R I V E R
*--------------------------------
Xopen    TST.B   D0
         BNE.S   .0
         LEA     FS6(PC),A1
         LEA     FS7(PC),A2
         BRA.S   .1
.0       LEA     FS8(PC),A1
         LEA     FS9(PC),A2
.1       LEA     lnkPCR(A5),A0
         MOVE.L  A1,ioNamePtr(A0)
         CLR.B   ioPermssn(A0)
         _Open
         MOVE    ioRefNum(A0),lnkRCI(A5)
         LEA     lnkPCS(A5),A0
         MOVE.L  A2,ioNamePtr(A0)
         CLR.B   ioPermssn(A0)
         _Open
         MOVE    ioRefNum(A0),lnkRCO(A5)
         LEA     lnkPCS(A5),A0
         MOVE    lnkRCO(A5),ioRefNum(A0)
         MOVE    #8,csCode(A0)
         MOVE    #$6C5E,csParam(A0)
         _Control
         MOVE    #9,csCode(A0)
         LEA     lnkBCR(A5),A1
         MOVE.L  A1,csParam(A0)
         MOVE    #1024,csParam+4(A0)
         _Control
         MOVE    #10,csCode(A0)
         CLR.L   csParam(A0)
         CLR.L   csParam+4(A0)
         _Control
         _KillIO
         MOVE.L  #4*60,padTO(A5)
Xreset   CLR     xmsLenR(A5)
         CLR     xmsLenS(A5)
         CLR.B   padPW(A5)
         CLR.B   padPS(A5)
         CLR.B   padPR(A5)
         MOVE.B  #-1,padPJ(A5)
         CLR.L   padT15(A5)
         CLR.L   padT17(A5)
         CLR.B   padOvfR(A5)
         CLR.B   padFlwS(A5)
         CLR.B   lnkFlgR(A5)
         CLR.L   lnkT10(A5)
         RTS
Xclose   LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE    #9,csCode(A0)
         LEA     lnkBCR(A5),A1
         MOVE.L  A1,csParam(A0)
         MOVE    #0,csParam+4(A0)
         _Control
         _KillIO
         RTS
FS6      STR     ".AIn"
FS7      STR     ".AOut"
FS8      STR     ".BIn"
FS9      STR     ".BOut"
Xset     CMP     #1,D0
         BHI.S   .0
         MOVE.L  #8*60,padTO(A5)
         BRA.S   .1
.0       CMP     #3,D0
         BHI.S   .2
         MOVE.L  #4*60,padTO(A5)
.1       ADD     D0,D0
         LEA     lnkPCS(A5),A0
         MOVE    lnkRCO(A5),ioRefNum(A0)
         MOVE    #8,csCode(A0)
         MOVE    .10(PC,D0),csParam(A0)
         _Control
.2       RTS
.10      DATA    /$6D7C,/$6CBD,/$6C5E,/$6C2E
Xinput   MOVE.L  A0,xmsBufR(A5)
         MOVE    D0,xmsLenR(A5)
         CLR.B   padOvfR(A5)
         RTS
Xoutput  MOVE.L  A0,xmsBufS(A5)
         MOVE    D0,xmsLenS(A5)
         RTS
Xstatus  BSR     padRcv
         BSR     padSnd
         BSR     XgetDCD
         SEQ     D3
         MOVE.B  padOvfR(A5),D2
         MOVE    xmsLenS(A5),D1
         MOVE    xmsLenR(A5),D0
         RTS
Xgetchr  MOVE.L  A0,A1
         LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  D0,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Read
         RTS
Xputchr  MOVE.L  A0,A1
         LEA     lnkPCS(A5),A0
         MOVE    lnkRCO(A5),ioRefNum(A0)
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  D0,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Write
         RTS
Xstachr  LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE    #2,csCode(A0)
         _Status
         MOVE.L  csParam(A0),D0
         RTS
XgetDCD  LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE    #8,csCode(A0)
         _Status
         MOVE.B  csParam+4(A0),D0
         CMP.B   xmsDCD(A5),D0
         RTS
XputDCD  LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE    #8,csCode(A0)
         _Status
         MOVE.B  csParam+4(A0),xmsDCD(A5)
         RTS
*++++++++++++++++++++++++++++++++
*         P A D
*--------------------------------
padRcv   BSR     lnkRcv
         BEQ.S   .3
         MOVE.B  lnkIDR(A5),D0
         MOVE.B  D0,D1
         AND.B   #$0F,D1
         LSR.B   #4,D0
         CMP.B   #8,D0
         BEQ.S   .4
         CMP.B   #2,D0
         BNE.S   .1
         TST.B   padPJ(A5)
         BPL.S   .0
         MOVE.B  padPS(A5),padPJ(A5)
.0       MOVE.B  D1,padPS(A5)
.1       MOVE.B  D1,padPW(A5)
         CLR.L   D0
         CMP.B   padPS(A5),D1
         BEQ.S   .2
         MOVE.L  Ticks,D0
         ADD.L   padTO(A5),D0
.2       MOVE.L  D0,padT15(A5)
.3       RTS
.4       CMP.B   padPR(A5),D1
         BEQ.S   .8
         ADDQ.B  #1,D1
         AND.B   #$0F,D1
         CMP.B   padPR(A5),D1
         BNE.S   .5
         MOVE.B  #1,padFlwS(A5)
         RTS
.5       TST.L   padT17(A5)
         BNE.S   .7
.6       MOVE.B  #2,padFlwS(A5)
.7       RTS
.8       CLR.L   padT17(A5)
         TST     D7
         BMI.S   .6
         MOVE.B  #1,padFlwS(A5)
         ADDQ.B  #1,padPR(A5)
         AND.B   #$0F,padPR(A5)
         CLR     D0
         MOVE.B  lnkLenR(A5),D0
         CMP     xmsLenR(A5),D0
         BLS.S   .9
         MOVE.B  #1,padOvfR(A5)
         MOVE    xmsLenR(A5),D0
.9       SUB     D0,xmsLenR(A5)
         LEA     lnkBufR(A5),A0
         MOVE.L  xmsBufR(A5),A1
         BRA.S   .11
.10      MOVE.B  (A0)+,(A1)+
.11      DBRA    D0,.10
         MOVE.L  A1,xmsBufR(A5)
         RTS
*--------------------------------
padSnd   TST     lnkPCS+ioResult(A5)
         BGT     .10
         MOVE.L  padT17(A5),D0
         BEQ.S   .0
         CMP.L   Ticks,D0
         BHI.S   .0
         MOVE.B  #2,padFlwS(A5)
.0       MOVE.B  padFlwS(A5),D0
         BEQ.S   .2
         CLR.B   padFlwS(A5)
         CMP.B   #2,D0
         BNE.S   .1
         MOVE.L  Ticks,D1
         ADD.L   padTO(A5),D1
         MOVE.L  D1,padT17(A5)
.1       BRA     lnkSnd
.2       MOVE.B  padPJ(A5),D0
         BMI.S   .3
         CMP.B   padPS(A5),D0
         BNE.S   .7
         MOVE.B  #-1,padPJ(A5)
.3       MOVE    xmsLenS(A5),D1
         BEQ.S   .11
         MOVE.B  padPS(A5),D0
         SUB.B   padPW(A5),D0
         AND.B   #$0F,D0
         CMP.B   #4,D0
         BHS.S   .11
         CMP     #128,D1
         BLS.S   .4
         MOVE    #128,D1
.4       SUB     D1,xmsLenS(A5)
         MOVE.B  padPS(A5),D0
         AND     #$0003,D0
         LEA     padLenS(A5),A1
         MOVE.B  D1,0(A1,D0)
         LSL     #7,D0
         LEA     padBufS(A5),A1
         ADD     D0,A1
         MOVE.L  xmsBufS(A5),A0
         BRA.S   .6
.5       MOVE.B  (A0)+,(A1)+
.6       DBRA    D1,.5
         MOVE.L  A0,xmsBufS(A5)
.7       TST.L   padT15(A5)
         BNE.S   .9
.8       MOVE.L  Ticks,D0
         ADD.L   padTO(A5),D0
         MOVE.L  D0,padT15(A5)
.9       MOVE.B  #8,D0
         BSR     lnkSnd
         ADDQ.B  #1,padPS(A5)
         AND.B   #$0F,padPS(A5)
.10      RTS
.11      MOVE.L  padT15(A5),D0
         BEQ.S   .10
         CMP.L   Ticks,D0
         BHI.S   .10
         SUBQ.B  #1,padPS(A5)
         AND.B   #$0F,padPS(A5)
         BRA.S   .8
*++++++++++++++++++++++++++++++++
*        L I N K
*--------------------------------
lnkRcv   LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         MOVE    #2,csCode(A0)
         _Status
         TST.L   csParam(A0)
         BNE.S   .1
         MOVE.L  lnkT10(A5),D0
         BEQ.S   .0
         CMP.L   Ticks,D0
         BHI.S   .0
         CLR.B   lnkFlgR(A5)
         CLR.L   lnkT10(A5)
.0       MOVEQ   #0,D7
         RTS
.1       LEA     lnkPCR(A5),A0
         MOVE    lnkRCI(A5),ioRefNum(A0)
         CLR.B   -(SP)
         MOVE.L  A7,ioBuffer(A0)
         MOVE.L  #1,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Read
         MOVE.B  (SP)+,D0
         CLR     D7
         MOVE.B  lnkFlgR(A5),D7
         ADD     D7,D7
         MOVE    .2(PC,D7),D7
         JMP     .2(PC,D7)
.2       DATA    /.10-.2
         DATA    /.20-.2
         DATA    /.30-.2
         DATA    /.40-.2
         DATA    /.50-.2
         DATA    /.60-.2
         DATA    /.70-.2
         DATA    /.80-.2
.10      CMP.B   #STX,D0
         BNE.S   lnkRcv
.11      MOVE    #-1,lnkCRC(A5)
.12      ADDQ.B  #1,lnkFlgR(A5)
.13      MOVE.L  Ticks,D0
         ADD.L   #1*60,D0
         MOVE.L  D0,lnkT10(A5)
         BRA     lnkRcv
.20      MOVE.B  D0,lnkLenR(A5)
         BSR.S   .90
         BRA.S   .12
.30      MOVE.B  D0,lnkIDR(A5)
         BSR.S   .90
         BRA.S   .12
.40      BSR.S   .90
         BRA.S   .12
.50      BSR.S   .90
         TST     lnkCRC(A5)
         BEQ.S   .51
         CLR.B   lnkFlgR(A5)
         CLR.L   lnkT10(A5)
         BRA     lnkRcv
.51      TST.B   lnkLenR(A5)
         BNE.S   .53
.52      CLR.B   lnkFlgR(A5)
         CLR.L   lnkT10(A5)
         MOVEQ   #1,D7
         RTS
.53      CLR     lnkCntR(A5)
         BRA.S   .11
.60      LEA     lnkBufR(A5),A0
         MOVE    lnkCntR(A5),D6
         MOVE.B  D0,0(A0,D6)
         BSR.S   .90
         ADDQ    #1,D6
         CMP.B   lnkLenR(A5),D6
         BEQ.S   .12
         MOVE    D6,lnkCntR(A5)
         BRA.S   .13
.70      BSR.S   .90
         BRA.S   .12
.80      BSR.S   .90
         TST     lnkCRC(A5)
         BEQ.S   .52
         CLR.B   lnkFlgR(A5)
         CLR.L   lnkT10(A5)
         MOVEQ   #-1,D7
         RTS
.90      MOVE    lnkCRC(A5),D7
         MOVEQ   #8-1,D1
.91      LSL.B   #1,D0
         ROXL    #1,D7
         BCC.S   .92
         EOR     #$1021,D7
.92      DBRA    D1,.91
         MOVE    D7,lnkCRC(A5)
         RTS
*--------------------------------
lnkSnd   CLR     D5
         MOVE.B  D0,D6
         LSL.B   #4,D6
         CMP.B   #8,D0
         BEQ.S   .0
         OR.B    padPR(A5),D6
         BRA.S   .1
.0       MOVE.B  padPS(A5),D0
         OR.B    D0,D6
         AND     #$0003,D0
         LEA     padLenS(A5),A1
         MOVE.B  0(A1,D0),D5
         LSL     #7,D0
         LEA     padBufS(A5),A1
         ADD     D0,A1
.1       LEA     lnkBufS(A5),A0
         MOVE.B  #STX,(A0)+
         MOVEQ   #1,D4
         MOVE    #-1,D7
         MOVE.B  D5,D0
         BSR.S   .20
         MOVE.B  D6,D0
         BSR.S   .20
         BSR.S   .10
         TST     D5
         BEQ.S   .4
         MOVE    #-1,D7
         BRA.S   .3
.2       MOVE.B  (A1)+,D0
         BSR.S   .20
.3       DBRA    D5,.2
         BSR.S   .10
.4       LEA     lnkPCS(A5),A0
         CLR.L   ioCompletion(A0)
         MOVE    lnkRCO(A5),ioRefNum(A0)
         LEA     lnkBufS(A5),A1
         MOVE.L  A1,ioBuffer(A0)
         MOVE.L  D4,ioReqCount(A0)
         CLR     ioPosMode(A0)
         _Write  ,ASYNC
         RTS
.10      MOVEQ   #0,D0
         BSR.S   .21
         MOVEQ   #0,D0
         BSR.S   .21
         ROR     #8,D7
         MOVE.B  D7,(A0)+
         ROR     #8,D7
         MOVE.B  D7,(A0)+
         RTS
.20      MOVE.B  D0,(A0)+
.21      MOVEQ   #8-1,D1
.22      LSL.B   #1,D0
         ROXL    #1,D7
         BCC.S   .23
         EOR     #$1021,D7
.23      DBRA    D1,.22
         ADDQ.L  #1,D4
         RTS
*++++++++++++++++++++++++++++++++
         ENDR
*================================
         RSRC    CDEF,128,resPreLoad
;
CDEF128  BRA.S   .0
         DATA    /0
         ASC     "CDEF"
         DATA    /128
         DATA    /0
.0       LINK    A6,#-8
         MOVE.L  A2,-(SP)
         CLR.L   20(A6)
         MOVE.L  14(A6),A0
         MOVE.L  (A0),A2
         MOVE    12(A6),D0
         BEQ.S   .2
         SUBQ    #1,D0
         BEQ.S   .1
         SUBQ    #1,D0
         BNE.S   .3
         MOVE.L  8(A6),-(SP)             ; calcRgns
         PEA     contrlRect(A2)
         _RectRgn
         BRA.S   .3
.1       CLR.B   -(SP)                   ; testCntl
         MOVE.L  8(A6),-(SP)
         PEA     contrlRect(A2)
         _PtInRect
         TST.B   (SP)+
         BEQ.S   .3
         MOVE    #1,22(A6)
         BRA.S   .3
.2       TST.B   contrlVis(A2)           ; drawCntl
         BEQ.S   .3
         PEA     contrlRect(A2)
         CLR.L   -(SP)
         MOVE    contrlRFcon+2(A2),-(SP)
         _GetIcon
         _PlotIcon
         TST     contrlValue(A2)
         SNE     D0
         TST.B   contrlHilite(A2)
         SNE     D1
         EOR.B   D1,D0
         BEQ.S   .3
         MOVE.L  contrlRect+topLeft(A2),-8+topLeft(A6)
         MOVE.L  contrlRect+botRight(A2),-8+botRight(A6)
         PEA     -8(A6)
         MOVE.L  OneOne,-(SP)
         _InsetRect
         PEA     -8(A6)
         _InverRect
.3       MOVE.L  (SP)+,A2
         UNLK    A6
         MOVE.L  (SP)+,A0
         ADD     #12,A7
         JMP     (A0)
;
         ENDR
*--------------------------------
         RSRC    MBAR,128,resPreLoad
         DATA    /3
         DATA    /128,/129,/130
         ENDR
*--------------------------------
         RSRC    MENU,128,resPreLoad
         DATA    /128
         DATA    /0,/0
         DATA    /0
         DATA    /0
         DATA    $FFFFFFFB
         HEX     0114
         STR     "About MCS…"
         DATA    #0,#0,#0,#0
         STR     "-"
         DATA    #0,#0,#0,#0
         STR     ""
         ENDR
*--------------------------------
         RSRC    MENU,129,resPreLoad
         DATA    /129
         DATA    /0,/0
         DATA    /0
         DATA    /0
         DATA    $FFFFFFD1
         STR     "File"
         STR     "Dial"
         DATA    #0,#'D',#0,#0
         STR     "Hang Up"
         DATA    #0,#'H',#0,#0
         STR     "-"
         DATA    #0,#0,#0,#0
         STR     "Settings…"
         DATA    #0,#0,#0,#0
         STR     "-"
         DATA    #0,#0,#0,#0
         STR     "Quit"
         DATA    #0,#'Q',#0,#0
         STR     ""
         ENDR
*--------------------------------
         RSRC    MENU,130,resPreLoad
         DATA    /130
         DATA    /0,/0
         DATA    /0
         DATA    /0
         DATA    $FFFFFF81
         STR     "Edit"
         STR     "Undo"
         DATA    #0,#'Z',#0,#0
         STR     "-"
         DATA    #0,#0,#0,#0
         STR     "Cut"
         DATA    #0,#'X',#0,#0
         STR     "Copy"
         DATA    #0,#'C',#0,#0
         STR     "Paste"
         DATA    #0,#'V',#0,#0
         STR     "Clear"
         DATA    #0,#0,#0,#0
         STR     ""
         ENDR
*--------------------------------
         RSRC    ALRT,128,resPreLoad
         DATA    /000,/000,/087,/295
         DATA    /128
         DATA    /$4444
         ENDR
*--------------------------------
         RSRC    DITL,128,resPreLoad
         DATA    /5-1
         DITM    4,58,14,78,78,"OK"
         DICN    32+128,10,30,42,62,128
         DITM    8+128,10,95,26,280,"MCS version 1.1"
         DITM    8+128,35,95,51,280,"written by Yves Lempereur"
         DITM    8+128,60,95,76,280,"Copyright 1988, Mainstay"
         ENDR
*--------------------------------
         RSRC    DLOG,200,resPreLoad
         DATA    /000,/000,/167,/340
         DATA    /dBoxProc
         DATA    #0,#0
         DATA    #0,#0
         DATA    0
         DATA    /200
         STR     ""
         ENDR
*--------------------------------
         RSRC    DITL,200,resPreLoad
         DATA    /18-1
         DITM    4,138,270,158,330,"OK"
         DITM    4,138,200,158,260,"Cancel"
         DITM    6,50,5,66,60,"300"
         DITM    6,65,5,81,60,"600"
         DITM    6,50,60,66,115,"1200"
         DITM    6,65,60,81,115,"2400"
         DITM    6,50,130,66,245,"Pulse (rotary)"
         DITM    6,65,130,81,245,"Touch-Tone™"
         DICN    7,50,260,82,292,200
         DICN    7,50,300,82,332,201
         DITM    16,110,10,126,330,""
         DITM    16,140,10,156,185,""
         DITM    8+128,5,5,21,335,"MCS Settings:"
         DITM    8+128,30,5,46,115,"Baud Rate:"
         DITM    8+128,30,130,46,245,"Phone:"
         DITM    8+128,30,260,46,335,"Port:"
         DITM    8+128,90,5,106,335,"Phone #:"
         DITM    0+128,134,266,162,334,""
         ENDR
*--------------------------------
         RSRC    CNTL,200,resPreLoad
         DATA    /000,/000,/032,/032
         DATA    /0
         DATA    #1,#0
         DATA    /1
         DATA    /0
         DATA    /2048
         DATA    200
         STR     ""
         ENDR
*--------------------------------
         RSRC    CNTL,201,resPreLoad
         DATA    /000,/000,/032,/032
         DATA    /0
         DATA    #1,#0
         DATA    /1
         DATA    /0
         DATA    /2048
         DATA    201
         STR     ""
         ENDR
*--------------------------------
         RSRC    ICON,128,resPreLoad
         HEX     003FF800.00FFFE00.01FFFF00.03FFFF80
         HEX     07FFFFC0.07FFFFC0.0FFFFFE0.0FFFF8E0
         HEX     0FE000E0.1E000070.1C000070.1C000070
         HEX     1C000070.1CFC7E70.0D000160.1C7C7C70
         HEX     14D45650.14383850.14000050.0C028060
         HEX     0C028060.04044040.0406C040.04000040
         HEX     02000080.021FF080.01000100.01038100
         HEX     01800300.01400500.01200900.011FF100
         ENDR
*--------------------------------
         RSRC    ICON,200,resPreLoad
         HEX     7FFFFFFE.80000001.80000001.80000031
         HEX     80000049.81C00049.82200131.84100081
         HEX     88100641.88080901.90080901.90082601
         HEX     90101001.9060C801.88812001.88812001
         HEX     8484C001.84420001.82210001.82100E01
         HEX     81081181.80842041.80422021.8021C021
         HEX     80100021.800C0041.80030081.8000C301
         HEX     80003C01.80000001.80000001.7FFFFFFE
         ENDR
*--------------------------------
         RSRC    ICON,201,resPreLoad
         HEX     7FFFFFFE.80000001.80000001.80000001
         HEX     80FFC001.80806001.80805001.80804801
         HEX     80804401.80807E01.80800201.80800201
         HEX     80800201.80800201.80800201.80800201
         HEX     80800201.80800201.8F8003E1.88800221
         HEX     88800239.88FFFE29.88000029.88000029
         HEX     88000039.88000021.88000021.8FFFFFE1
         HEX     80000001.80000001.80000001.7FFFFFFE
         ENDR
*--------------------------------
         RSRC    vers,1,resPurgeable
         DATA    #$01,#$10,#release,#$00,/verUS
         STR     "1.1"
         STR     "1.1, ©1988 Mainstay"
         ENDR
*--------------------------------
         RSRC    MCS1,0,resPurgeable
         STR     "MCS v1.1 -- 08/26/88"
         ENDR
*--------------------------------
         RSRC    ICN#,128,resPurgeable
         HEX     00000000.7FFFFFFE.40000002.5FFFFFFB
         HEX     5000000B.577DF00B.5000000B.55DF000B
         HEX     5000000B.56F7DE0B.5000000B.5770000B
         HEX     5000000B.56FBC00B.5000000B.57BE000B
         HEX     5000000B.5000000B.5FFFFFFB.40000003
         HEX     5FFFFFFB.5555555B.5AAAAAAB.5FFFFFFB
         HEX     40000003.5FFFFFFB.5555555B.5AAAAAAB
         HEX     5FFFFFFB.40000003.7FFFFFFF.1FFFFFFF
*
         HEX     00000000.7FFFFFFE.7FFFFFFE.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.7FFFFFFF
         HEX     7FFFFFFF.7FFFFFFF.7FFFFFFF.1FFFFFFF
         ENDR
*--------------------------------
         RSRC    FREF,128,resPurgeable
         ASC     "APPL"
         DATA    /0
         STR     ""
         ENDR
*--------------------------------
         RSRC    BNDL,128,resPurgeable
         ASC     "MCS1"
         DATA    /0
         DATA    /2-1
         ASC     "ICN#"
         DATA    /1-1
         DATA    /0,/128
         ASC     "FREF"
         DATA    /1-1
         DATA    /0,/128
         ENDR
*--------------------------------
         RSRC    CNFG,128,resPreLoad
         DATA    /0,/2,/1
         STR     "E0M1Q0V1X1"
         STR     "1-(818) 991-5037"
         ENDR
*================================
         END
