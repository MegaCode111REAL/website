#!/bin/bash

echo "🔧 Updating system..."
sudo apt update -y

echo "📦 Installing Node.js and npm..."
sudo apt install -y nodejs npm

echo "📁 Creating project folder..."
mkdir -p ~/localdrop
cd ~/localdrop

echo "📦 Initializing npm..."
npm init -y

echo "📦 Installing dependencies..."
npm install express socket.io multer

echo "📁 Creating folders..."
mkdir -p public uploads

echo "🧠 Creating server.js..."
cat > server.js << 'EOF'
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const multer = require("multer");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const upload = multer({ dest: "uploads/" });

app.use(express.static("public"));
app.use("/files", express.static("uploads"));

io.on("connection", (socket) => {
    console.log("User connected");

    socket.on("chat", (msg) => {
        io.emit("chat", msg);
    });

    socket.on("disconnect", () => {
        console.log("User disconnected");
    });
});

app.post("/upload", upload.single("file"), (req, res) => {
    const file = req.file;
    const fileUrl = "/files/" + file.filename;

    io.emit("file", {
        name: file.originalname,
        url: fileUrl
    });

    res.sendStatus(200);
});

server.listen(3000, () => {
    console.log("Server running on port 3000");
});
EOF

echo "🌐 Creating frontend..."
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>LocalDrop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: sans-serif; margin: 0; padding: 10px; }
        #chat { height: 60vh; overflow-y: auto; border: 1px solid #ccc; padding: 10px; }
        input, button { font-size: 16px; margin-top: 5px; }
    </style>
</head>
<body>

<h2>📡 LocalDrop</h2>

<div id="chat"></div>

<input id="msg" placeholder="Message">
<button onclick="send()">Send</button>

<hr>

<input type="file" id="file">
<button onclick="upload()">Send File</button>

<script src="/socket.io/socket.io.js"></script>
<script>
const socket = io();
const chat = document.getElementById("chat");

function add(text) {
    const div = document.createElement("div");
    div.innerHTML = text;
    chat.appendChild(div);
    chat.scrollTop = chat.scrollHeight;
}

function send() {
    const msg = document.getElementById("msg").value;
    if (!msg) return;
    socket.emit("chat", msg);
    document.getElementById("msg").value = "";
}

socket.on("chat", (msg) => {
    add("💬 " + msg);
});

socket.on("file", (file) => {
    add(`📁 <a href="${file.url}" target="_blank">${file.name}</a>`);
});

function upload() {
    const fileInput = document.getElementById("file");
    if (!fileInput.files.length) return;

    const formData = new FormData();
    formData.append("file", fileInput.files[0]);

    fetch("/upload", {
        method: "POST",
        body: formData
    });

    fileInput.value = "";
}
</script>

</body>
</html>
EOF

echo "🚀 Starting server..."
node server.js
