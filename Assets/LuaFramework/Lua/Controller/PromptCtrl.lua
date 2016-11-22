require "Common/define"

require "3rd/pblua/login_pb"
require "3rd/pbc/protobuf"

local sproto = require "3rd/sproto/sproto"
local core = require "sproto.core"
local print_r = require "3rd/sproto/print_r"

PromptCtrl = {};
local this = PromptCtrl;

local panel;
local prompt;
local transform;
local gameObject;

--构建函数--
function PromptCtrl.New()
	logWarn("PromptCtrl.New--->>");
	return this;
end

function PromptCtrl.Awake()
	logWarn("PromptCtrl.Awake--->>");
	panelMgr:CreatePanel('Prompt', this.OnCreate);
end

--启动事件--
function PromptCtrl.OnCreate(obj)
	gameObject = obj;
	transform = obj.transform;

	panel = transform:GetComponent('UIPanel');
	prompt = transform:GetComponent('LuaBehaviour');
	logWarn("Start lua--->>"..gameObject.name);

	this.InitPanel();	--初始化面板--
	prompt:AddClick(PromptPanel.btnOpen, this.OnClick);
end

local m_GridParent;

--初始化面板--
function PromptCtrl.InitPanel()
	panel.depth = 1;	--设置纵深--
	m_GridParent = PromptPanel.gridParent;
	local itemPrefab = prompt:LoadAsset('PromptItem');
	for i = 1, 100 do
		local go = newObject(itemPrefab);
		go.name = tostring(i);
		go.transform.parent = m_GridParent;
		go.transform.localScale = Vector3.one;
		go.transform.localPosition = Vector3.zero;
		prompt:AddClick(go, this.OnItemClick);

		local goo = go.transform:FindChild('Label');
		goo:GetComponent('UILabel').text = i;
	end
	local grid = m_GridParent:GetComponent('UIGrid');
	grid:Reposition();
	grid.repositionNow = true;
    -- m_GridParent:GetComponent('WrapGrid'):InitGrid();
    InitGrid();
end

local mChildren = {};
local mTrans;
local mPanel;
local mScroll;
local mHorizontal = false;

function SortByName(a, b)
    return a[1].name < b[1].name;
end

function InitGrid() 

    mTrans = transform;
    mPanel = m_GridParent:GetComponentInParent(System.Type.GetType('UIPanel'));
    mScroll = mPanel:GetComponent('UIScrollView');

    if mScroll ~= nil then
        mScroll:GetComponent('UIPanel').onClipMove = OnMove;
    end       

    for i = 0, m_GridParent.parent.childCount - 1 do
        mChildren[i] = m_GridParent.parent:GetChild(i);
    end

    table.sort(mChildren, SortByName);

    if mScroll == nil then
        return;
    end

    if mScroll.movement == 0 then
        mHorizontal = true;
        else if mScroll.movement == 1 then
            mHorizontal = false;
        end
    end

    WrapContent();
end

function OnMove(panel)
    WrapContent();
end

function WrapContent()       
    local corners = mPanel.worldCorners;

    for i = 0, 3 do
        local v = corners[i];
        v = UnityEngine.Transform.InverseTransformPoint(mTrans, v);
        corners[i] = v;
    end

    local center = Vector3.Lerp(corners[0], corners[2], 0.5);

    if mHorizontal then
        for key, value in pairs(mChildren) do
            local t = value;
            local distance = t.localPosition.x - center.x;
            local min = corners[0].x - 100;
            local max = corners[2].x + 100;         

            distance = distance + mPanel.clipOffset.x - mTrans.localPosition.x;
            if UICamera.IsPressed(t.gameObject) == false then
                NGUITools.SetActive(t.gameObject, (distance > min and distance < max), false);
            end
        end
    else
        for key, value in pairs(mChildren) do       
            local distance = value.localPosition.y - center.y;
            local min = corners[0].y - 100;
            local max = corners[2].y + 100;

            distance = distance + mPanel.clipOffset.y - mTrans.localPosition.y;
            if UICamera.IsPressed(value.gameObject) == false then
                local active = value.gameObject.activeSelf;
                local willactive = distance > min and distance < max;
                if active ~= willactive then
                    -- NGUITools.SetActive(value.gameObject, willactive, false);
                end              
            end
        end
    end
end

        --滚动项单击事件--
        function PromptCtrl.OnItemClick(go)
         log(go.name);
     end

     --单击事件--
     function PromptCtrl.OnClick(go)
         if TestProtoType == ProtocalType.BINARY then
          this.TestSendBinary();
      end
      if TestProtoType == ProtocalType.PB_LUA then
          this.TestSendPblua();
      end
      if TestProtoType == ProtocalType.PBC then
          this.TestSendPbc();
      end
      if TestProtoType == ProtocalType.SPROTO then
          this.TestSendSproto();
      end
      logWarn("OnClick---->>>"..go.name);
  end

  --测试发送SPROTO--
  function PromptCtrl.TestSendSproto()
  local sp = sproto.parse [[
  .Person {
  name 0 : string
  id 1 : integer
  email 2 : string

  .PhoneNumber {
  number 0 : string
  type 1 : integer
}

phone 3 : *PhoneNumber
}

.AddressBook {
person 0 : *Person(id)
others 1 : *Person
}
]]

local ab = {
person = {
[10000] = {
name = "Alice",
id = 10000,
phone = {
{ number = "123456789" , type = 1 },
{ number = "87654321" , type = 2 },
}
},
[20000] = {
name = "Bob",
id = 20000,
phone = {
{ number = "01234567890" , type = 3 },
}
}
},
others = {
{
    name = "Carol",
    id = 30000,
    phone = {
    { number = "9876543210" },
}
},
}
}
local code = sp:encode("AddressBook", ab)
----------------------------------------------------------------
local buffer = ByteBuffer.New();
buffer:WriteShort(Protocal.Message);
buffer:WriteByte(ProtocalType.SPROTO);
buffer:WriteBuffer(code);
networkMgr:SendMessage(buffer);
end

--测试发送PBC--
function PromptCtrl.TestSendPbc()
local path = Util.DataPath.."lua/3rd/pbc/addressbook.pb";

local addr = io.open(path, "rb")
local buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local addressbook = {
name = "Alice",
id = 12345,
phone = {
{ number = "1301234567" },
{ number = "87654321", type = "WORK" },
}
}
local code = protobuf.encode("tutorial.Person", addressbook)
----------------------------------------------------------------
local buffer = ByteBuffer.New();
buffer:WriteShort(Protocal.Message);
buffer:WriteByte(ProtocalType.PBC);
buffer:WriteBuffer(code);
networkMgr:SendMessage(buffer);
end

--测试发送PBLUA--
function PromptCtrl.TestSendPblua()
local login = login_pb.LoginRequest();
login.id = 2000;
login.name = 'game';
login.email = 'jarjin@163.com';
local msg = login:SerializeToString();
----------------------------------------------------------------
local buffer = ByteBuffer.New();
buffer:WriteShort(Protocal.Message);
buffer:WriteByte(ProtocalType.PB_LUA);
buffer:WriteBuffer(msg);
networkMgr:SendMessage(buffer);
end

--测试发送二进制--
function PromptCtrl.TestSendBinary()
local buffer = ByteBuffer.New();
buffer:WriteShort(Protocal.Message);
buffer:WriteByte(ProtocalType.BINARY);
buffer:WriteString("ffff我的ffffQ靈uuu");
buffer:WriteInt(200);
networkMgr:SendMessage(buffer);
end

--关闭事件--
function PromptCtrl.Close()
	panelMgr:ClosePanel(CtrlNames.Prompt);
end