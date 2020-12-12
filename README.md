#  Pac-Man

I always wanted to program my own Pac-Man game. However, I have always put it on the back burner. But now the childhood dream has come true. And this is the result: A Pac-Man game (aka Mac-Pan because it was written on a Mac) for the Apple TV (tvOS) programmed with Swift using the SpriteKit framework.

The whole thing is unlikely to interest you. Why should it. There are already plenty of Pac-Man games. To get me to play it at all from time to time, I implemented a two-player mode, which is fun. The goal is to eat all the pellets before your opponent does. If you don't have an opponent you can play the game alone. The best time is saved as a record.

![Screenshot](https://roger-wetzel.github.io/images/Pac-Man.png)

## Installation

- Open the file `Pacman.xcodeproj` with Xcode
- Optional: Select `Assets.xcassets` > `soundtrack` in the project navigator and drag in your favorite 80s song as mp3 or m4a file. [Don't You Want Me](https://www.youtube.com/watch?v=uPudE8nDog0) by The Human League or [Obession](https://www.youtube.com/watch?v=lZVhZhLAwMQ) by Animotion are perfect.
- Build and run in a tvOS simulator or on a tvOS device

## Controls

### tvOS Simulator
Press the A key twice to start. Use the arrow keys to navigate Pac-Man. Only single-player mode is supported.

### tvOS Device

For the two-player mode you need two controllers or one controller and the Siri remote. Press the A button (or the touch pad on the Siri remote) and wait for the second player to join. The game will automatically start in versus mode.

## Implementation Details

A state machine takes care of the gameplay. The playfield is divided into 16x16 pixel tiles. The maze is drawn with some kind of [«Logo turtle graphics»](https://en.wikipedia.org/wiki/Logo_(programming_language)#Turtle_and_graphics) dialect. Pac-Man and the ghosts are `Figure`s. They always move in the direction of their direction vector and have different speeds. To ensure that the collision detection works reliably even at higher speeds, during one frame the `Figure`s are moved several times by one position, each time followed by the collision detection. This logic is pretty ugly and really nobody should look at this in detail. A nasty thing is also the `Autopilot` that leads the ghosts out and back into the home. Don't even try to understand it.

## Credits

- Coordinates and colors for all shapes are taken from Shaun Williams' amazing [Pac-Man remake](https://bitbucket.org/shaunew/pac-man/src/master/)
- [Arcade font](https://fontmeme.com/fonts/arcade-yuji-adachi-font/) designed by Yuji Adachi
- Most detail information are from the [Pac-Man Dossier](https://www.gamasutra.com/view/feature/132330/the_pacman_dossier.php?page=1)
- `.gitignore` file created with [gitignore.io](https://gitignore.io)
- `LICENSE` file created with [Choose an open source license](https://choosealicense.com)
