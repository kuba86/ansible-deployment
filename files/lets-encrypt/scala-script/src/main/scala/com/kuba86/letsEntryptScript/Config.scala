import caseapp._

case class LegoConfig(
    image: String = "default-image",
    version: String = "latest",
    podman: Boolean = false,
    ports: List[Int] = List.empty
)  

object LegoApp extends CaseApp[LegoConfig] {
    def run(config: LegoConfig, remainingArgs: List[String]): Unit = {
        println(s"Running Lego with config: $$config and remaining args: $$remainingArgs")
    }
}