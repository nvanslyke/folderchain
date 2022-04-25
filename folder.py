import os
from pytube import YouTube

path = ""
filename = ""

with  open("text.txt") as file:
    list = []
    for line in file:
        x = line
        x  = x[0:len(x)-1]
        list.append(x.split(" "))
    
newlist = []

for i in list:
    for j in i:
        newlist.append(j)
print(str(len(newlist)) + " words uploaded")
print()

totalchars = 0
for word in newlist:
    for char in word:
        totalchars += 1



def main():
    global path
    try:
        path = "C:\\Users\\nvans\\Desktop\\"  #copy and paste the path of where you want folder to be located
        for word in newlist:
            path += word + "\\" #change to "/" if on mac
            os.makedirs(path)
    except:
        print(path)
    print(path)
    print()
    print()

 
def audio():
    global filename
    URL = input("Enter Video URL: ") 
    yt = YouTube(URL)
    
    print()
    print(yt.title)

    try:
        print()
        print("Downloading.....")
        file = yt.streams.filter(only_audio=True).first()
        output = file.download(path)
        filename = output
        #base, x = os.path.splitext(output)
        #last = "file" + ".mp3"
        #os.rename(output, last)
        print()
        print("Successfully Downloaded File")
        print()

    except:
        print()
        print("Error Downloading File")   

def rename():

    try:
        old_name = filename
        new_name = path + "file.mp3"
        os.rename(old_name, new_name)
        print()
        print("Successfully Renamed File")
        print()
    except:
        print()
        print("Error renaming file")

if __name__  == '__main__':
    main()
    audio()
    rename()