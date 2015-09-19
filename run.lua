--[[
      Cloud program client
      by DvgCraft
      Wireless modem required
      
      DATE  07-07-2015
]]--

-- Variables
local version = "1.2.1"
local running = true
local tArgs = {...}
local dir = "/.DvgFiles/data/Cloud"

local username = ""
local pass = ""

local newUsername = ""
local newPass = ""
local userExists = nil
local mside = nil
local serverID = nil
local files = {}

-- Functions
function checkInstall()
  if not fs.exists("/.DvgFiles") then
    error("You have to install DvgFiles first. Download it here: (coming soon)")
  end
  if not fs.exists(dir) then
    fs.makeDir(dir)
    local file = fs.open(dir.."/version", "w")
    file.write(version)
    file.close()
    local file = fs.open(dir.."/serverID", "w")
    print("Server ID:")
    serverID = tonumber(read())
    file.write(serverID)
    file.close()
  end
  if not fs.exists("/.DvgFiles/settings/mside") then
    local file = fs.open("/.DvgFiles/settings/mside", "w")
    print("Modem side:")
    mside = read()
    file.write(mside)
    file.close()
  end
end

function register()
  print("Create username:")
  newUsername = read()
  print("Create password:")
  newPass = read()
  print("Confirm password:")
  if newPass ~= read() then
    error("Passwords do not correspond (#201.31)")
  end
  
  local newUser = {username = newUsername, pass = newPass}
  rednet.send(serverID, textutils.serialize(newUser), "DVG_CLOUD_NEWUSER_REQUEST")
  id, msg = rednet.receive("DVG_CLOUD_NEWUSER_ANSWER", 5)
  if msg == nil then
    error("Could not connect to server (#201.1)")
  elseif id == serverID then
    if msg == "SUCCESS" then
      print("User created. Login:")
    elseif msg == "FAILURE" then
      error("Username already exists. choose another (#201.32)")
    end
  end
end
function login(datagiven)
  if datagiven then
    username = tArgs[1]
    pass = tArgs[2]
  else
    print("Username:")
    username = read()
    print("Password:")
    pass = read()
  end
  local userInfo = {username = username, pass = pass}
  
  rednet.send(serverID, textutils.serialize(userInfo), "DVG_CLOUD_CHECKUSER_REQUEST")
  local id, msg = rednet.receive("DVG_CLOUD_CHECKUSER_ANSWER", 5)
  if msg == nil then
    error("Could not connect to server (#201.1)")
  end
  if msg == "SUCCESS" then
    userExists = true
  elseif msg == "FAILURE" then
    error("Username or password incorrect (#201.2)")
  else
    error("Something terrible happened! (#001)")
  end
end

function getFiles()
  rednet.send(serverID, username, "DVG_CLOUD_FILES_REQUEST")
  local id, msg = rednet.receive("DVG_CLOUD_FILES_ANSWER", 5)
  if msg == nil then
    msg  = {"Could not connect to server."}
    return msg
  elseif id == serverID then
    return textutils.unserialize(msg)
  end
end
function getFile(path, edit)
  local sendTab = {username = username, path = path}
  sendTab = textutils.serialize(sendTab)
  rednet.send(serverID, sendTab, "DVG_CLOUD_FILE_GET_REQUEST")
  print("Sent file request. waiting for answer...")
  local id, msg = rednet.receive("DVG_CLOUD_FILE_GET_ANSWER", 5)
  if msg == nil then
    print("Could not connect to server.")
    return false
  elseif msg == "FAILURE" then
    if edit then
      print("File name cannot be '#'")
    else
      print("No such program")
    end
    return false
  elseif id == serverID then
    local path = "/.DvgFiles/TEMP/Cloud_"..path
    
    msg = textutils.unserialize(msg)
    local file = fs.open(path, "w")
    for i = 1, #msg do
      file.writeLine(msg[i])
    end
    file.close()
    fs.delete(path)
    return true
  end
end
function edit(path)
  local returnTab = {username, path}
  local path = "/.DvgFiles/TEMP/Cloud_"..path
  shell.run("edit "..path)
  
  local file = fs.open(path, "r")
  line = file.readLine()
  while line do
    table.insert(returnTab, line)
    line = file.readLine()
  end
  file.close()
  fs.delete(path)
  
  rednet.send(serverID, textutils.serialize(returnTab), "DVG_CLOUD_FILE_POST_REQUEST")
end
function delete(path)
  local sendTab = {username, path}
  rednet.send(serverID, textutils.serialize(sendTab), "DVG_CLOUD_FILE_DELETE_REQUEST")
  local id, msg = rednet.receive("DVG_CLOUD_FILE_DELETE_ANSWER", 5)
  if msg == nil then
    print("Could not connect to server (#201.1)")
  elseif id == serverID then
    if msg == "SUCCESS" then
      print("File deleted.")
    elseif msg == "FAILURE" then
      print("File does not exist.")
    end
  end
end

-- Run
checkInstall()
if mside == nil then
  local file = fs.open("/.DvgFiles/settings/mside", "r")
  mside = file.readLine()
  file.close()
end
rednet.open(mside)

if serverID == nil then
  local file = fs.open("/.DvgFiles/data/Cloud/serverID", "r")
  serverID = tonumber(file.readLine())
  file.close()
end

if #tArgs == 2 then
  login(true)
else
  print("type L to login and R to register")
  input = read()
  if input:lower() == "r" then
    register()
  elseif input:lower() ~= "l" then
    running = false
  end
  login(false)
end

if not userExists then
  error("This should never happen... (#002)")
end

while running do
  write("Cloud> ")
  input = read()
  if #input == 0 then
    
  elseif input:sub(1,2) == "ls" then
    files = getFiles()
    textutils.pagedTabulate(files)
  elseif input:sub(1,4) == "edit" then
    local answer = getFile( input:sub(6), true )
    if answer then
      edit( input:sub(6) )
    end
  elseif input:sub(1,6) == "delete" or input:sub(1,6) == "remove" or input:sub(1,2) == "rm" then
    if input:sub(1,6) == "delete" or input:sub(1,6) == "remove" then
      sendTab = {username = username, path = input:sub(8)}
    elseif input:sub(1,2) == "rm" then
      sendTab = {username = username, path = input:sub(4)}
    end
    rednet.send(serverID, textutils.serialize(sendTab), "DVG_CLOUD_FILE_DELETE_REQUEST")
    local id, msg = rednet.receive("DVG_CLOUD_FILE_DELETE_ANSWER", 5)
    if msg == nil then
      print("Could not connect to server.")
    elseif msg == "FAILURE" then
      print("No matching files")
    end
  elseif input:lower() == "exit" then
    running = false
  else
    answer = getFile(input, false)
    if answer then
      shell.run("/.DvgFiles/TEMP/Cloud_"..input)
    end
  end
end
