import Basic
import Foundation
import Utility

/// Registry that contains all the commands.
public final class CommandRegistry {
    // Argument parser.
    private let parser: ArgumentParser

    /// Printer.
    private let printer: Printing

    /// Error handler.
    private let errorHandler: ErrorHandling

    // Registered commands.
    var commands: [Command] = []

    /// Returns the process arguments.
    private let processArguments: () -> [String]

    /// Initializes the command registry
    public init(processArguments: @escaping () -> [String] = CommandRegistry.processArguments) {
        printer = Printer()
        errorHandler = ErrorHandler(printer: printer)
        parser = ArgumentParser(usage: "<command> <options>",
                                overview: "Your Xcode buddy")
        self.processArguments = processArguments
        register(command: InitCommand.self)
        register(command: GenerateCommand.self)
        register(command: UpdateCommand.self)
        register(command: DumpCommand.self)
        register(command: VersionCommand.self)
    }

    /// Returns the process arguments
    ///
    /// - Returns: process arguments.
    public static func processArguments() -> [String] {
        return Array(ProcessInfo.processInfo.arguments)
    }

    /// Register a new command.
    ///
    /// - Parameter command: command type.
    func register(command: Command.Type) {
        commands.append(command.init(parser: parser))
    }

    /// Runs the command line interface.
    public func run() throws {
        let parsedArguments = try parse()
        do {
            try process(arguments: parsedArguments)
        } catch {
            // Errors shouldn't reach this point.
            // In case we do we should check where the error is coming from and:
            //  - Handle them if we can.
            //  - Use the error handler from the context to fail the execution.
            errorHandler.fatal(error: FatalError.bugSilent(error))
        }
    }

    /// Parses the CLI arguments that have been passed using the parser.
    ///
    /// - Returns: parsing result.
    /// - Throws: an error if the parsing fails.
    private func parse() throws -> ArgumentParser.Result {
        let arguments = Array(processArguments().dropFirst())
        return try parser.parse(arguments)
    }

    /// Process the parsing result.
    ///
    /// - Parameter arguments: parsing result.
    /// - Throws: an error if the output cannot be processed
    private func process(arguments: ArgumentParser.Result) throws {
        guard let subparser = arguments.subparser(parser),
            let command = commands.first(where: { $0.command == subparser }) else {
            parser.printUsage(on: stdoutStream)
            return
        }
        command.run(with: arguments)
    }
}
