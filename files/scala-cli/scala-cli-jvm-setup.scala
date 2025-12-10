#!/usr/bin/env -S scala-cli shebang --server=false --jvm graalvm-community:21

@main def main() = {
  println("graalvm-community:21 downloaded")
  println(s"Java home: ${sys.props("java.home")}")
}
