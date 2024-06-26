const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const fs = require("fs");
var admin = require("firebase-admin");

var serviceAccount = require("./babymonitoring-77863-firebase-adminsdk-z8vpz-f406736c17.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL:
    "https://babymonitoring-77863-default-rtdb.asia-southeast1.firebasedatabase.app",
});

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  pingTimeout: 60000, // Contoh parameter lain yang bisa disesuaikan
  maxHttpBufferSize: 1e8, // Batas buffer maksimum, dalam byte (contoh: 100 MB)
});

app.use(express.static("public"));

let videoChunks = Buffer.alloc(0);
let tempFilename;
let chunkss = [];

app.use(express.json());
app.get("/data", (req, res) => {
  res.send(chunkss);
});

app.get("/database", (req, res) => {
  let data = null;
  console.log("fetching..");
  database.ref("EoC8y_").once(
    "value",
    (snapshot) => {
      const data = snapshot.val();
      console.log(data);
      res.send(data);
    },
    (error) => {
      if (error) {
        console.log("Gagal membacaa data: " + error);
      } else {
        console.log("Berhasil membaca data");
      }
      res.send("Error");
    }
  );
});

app.post("/data", (req, res) => {
  let data = req.body;
  console.log(data);
  database.ref(data.token).set(
    {
      suhu: data.suhu,
      kelembapan: data.kelembapan,
    },
    (error) => {
      if (error) {
        res.send({
          status: "error",
          message: "Tidak bisa menulis data " + error,
        });
      } else {
        res.send({
          status: "sukses",
          message: "Data berhasil disimpan",
        });
      }
    }
  );
});

const database = admin.database();

io.on("connection", (socket) => {
  console.log("a user connected");
  let rooms = "";
  tempFilename = `temp-${Date.now()}.webm`;

  socket.on("join_room", (room) => {
    rooms = room;
    console.log("User joined room ", room);
    socket.join(room);
  });

  function getData(rooms) {
    database.ref("EoC8y_").once(
      "value",
      (snapshot) => {
        const data = snapshot.val();
        console.log(data);
        socket.to(rooms).emit("sensorData", {
          status: "sukses",
          data: data,
        });
      },
      (error) => {
        if (error) {
          console.log("Gagal membacaa data: " + error);
        } else {
          console.log("Berhasil membaca data");
        }
        socket.to(rooms).emit("sensorData", {
          status: "error",
          data: error,
        });
      }
    );
  }

  let chunkCount = 0;
  socket.on("videoChunk", async (chunk) => {
    chunkCount++;
    let curSize = chunk.length;
    console.log("Before del : ", curSize, "  After : ", chunk.length);
    socket.to(rooms).emit("videoChunk", chunk);
    getData(rooms);
    console.log("Send package to room ", rooms);
    console.log("Total chunk:", videoChunks.length);
    console.log(Object.values(chunk));
  });

  socket.on("disconnect", async () => {
    console.log("user disconnected");
  });
});

server.listen(3000, () => {
  console.log("listening on *:3000");
});
