#!/usr/bin/env -S scala-cli shebang --jvm graalvm-community:23.0.1

//> using dep "com.lihaoyi::os-lib::0.11.3"
//> using dep "com.lihaoyi::pprint::0.9.0"

import os.*

@main def main(name: String, age: Int) = {
  println("Hello, world!")
  println(name)
  println(age)
  // os.list(os.pwd).foreach(println)
}
