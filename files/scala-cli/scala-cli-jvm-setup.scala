#!/usr/bin/env -S scala-cli shebang --server=false --jvm graalvm-community:25

// check new versions: `cs java --available | grep graalvm-community`

@main def main() = {
  println("graalvm-community:25 downloaded")
  println(s"Java home: ${sys.props("java.home")}")
}
