unit MyCloudClientFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox, FMX.Memo,
  FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls,

  CoreClasses, PascalStrings, TextDataEngine, ListEngine, CommunicationFramework,
  DoStatusIO, UnicodeMixedLib, DataFrameEngine,
  CommunicationFrameworkDoubleTunnelIO_ServMan,
  CommunicationFramework_Client_Indy, ManagerClientAPI, MyCloudClientAPI;

type
  TForm1 = class(TForm)
    QueryButton: TButton;
    AddrEdit: TEdit;
    Memo: TMemo;
    Timer1: TTimer;
    QueryMinButton: TButton;
    WaitQueryButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure WaitQueryButtonClick(Sender: TObject);
    procedure QueryButtonClick(Sender: TObject);
    procedure QueryMinButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FManQueryCli: TCommunicationFramework_Client_Indy;
    FManQuery: TManagerQuery;
    FMyCloudClient: TMyCloudClient;
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

{ TForm1 }

procedure TForm1.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(AText);
  Memo.GoToTextEnd;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  FManQueryCli := TCommunicationFramework_Client_Indy.Create;
  FManQuery := TManagerQuery.Create(FManQueryCli);
  FMyCloudClient := TMyCloudClient.Create(TCommunicationFramework_Client_Indy);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(Self);
  DisposeObject(FManQuery);
  DisposeObject(FManQueryCli);
  DisposeObject(FMyCloudClient);
end;

procedure TForm1.QueryButtonClick(Sender: TObject);
begin
  // �첽��ѯȫ�ַ�����
  FManQuery.AsyncQuery(
    AddrEdit.Text, // ���ȷ�������ַ
    stLogic,       // ��ѯ��Ŀ�����������
      procedure(const state: Boolean)
    var
        a: TQueryResultInfo;
    begin
        // �������¼�ʱ�򣬱�ʾ�첽��ѯ�������Ѿ���ɣ�state��ʾ��ѯ״̬�Ƿ�ɹ�
        if state then
        begin
            DoStatus('�첽��ѯȫ�ַ��������');
            // ���ǿ�ʼ��������Ϣ
            for a in FManQuery.ServerList do
            begin
                if FMyCloudClient.Connect(a.Host, a.RecvPort, a.SendPort) then
                begin
                    DoStatus(FMyCloudClient.MyAPI(100, 99));
                    FMyCloudClient.Disconnect;
                end;
            end;
        end;
    end);
end;

procedure TForm1.QueryMinButtonClick(Sender: TObject);
begin
  // ��ѯȫ����С���ص�һ̨����������ѯ�����¼�ֻ����һ��
  FManQuery.Query(
    AddrEdit.Text, // ���ȷ�������ַ
    stLogic,       // ��ѯ��Ŀ�����������
      procedure(const state: Boolean; const Addr: TQueryResultInfo)
    begin
        // �����ǲ�ѯ�ķ�������
        if state then
        begin
            // ��ѯ�ɹ�ʱ��Addr������Ŀ��������ĵ�ַ���˿ڣ���ǰ���صȵ������Ϣ
            // ������Ʒ�������ܣ�ͨ������ķ�����Ϣ��Ŀ���������¼����
            DoStatus('��С���ط�������ѯ���');

            if FMyCloudClient.Connect(Addr.Host, Addr.RecvPort, Addr.SendPort) then
            begin
                DoStatus(FMyCloudClient.MyAPI(100, 99));
                FMyCloudClient.Disconnect;
            end;
        end
      else
          DoStatus('��С���ط�������ѯʧ��');
    end);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  FManQuery.Progress;
  FMyCloudClient.Progress;
end;

procedure TForm1.WaitQueryButtonClick(Sender: TObject);
var
  a: TQueryResultInfo;
begin
  // ����ʽ��ѯȫ�ַ����������صĲ�ѯ�����ServerList��
  FManQuery.WaitQuery(
    AddrEdit.Text, // ���ȷ�������ַ
    stLogic        // ��ѯ��Ŀ�����������
    );

  if FManQuery.ServerList.Count > 0 then
    for a in FManQuery.ServerList do
      begin
        DoStatus('���ȷ�������ѯ���');
        // ��ѯ�ɹ�ʱ��a��Ŀ��������ĵ�ַ���˿ڣ���ǰ���صȵ������Ϣ
        // ������Ʒ�������ܣ�ͨ������ķ�����Ϣ��Ŀ���������¼����
        if FMyCloudClient.Connect(a.Host, a.RecvPort, a.SendPort) then
          begin
            DoStatus(FMyCloudClient.MyAPI(100, 99));
            FMyCloudClient.Disconnect;
          end;
      end
  else
      DoStatus('���ȷ�������ѯʧ��');
end;

end.
