module Moped

  # Mongo's exceptions are sparsely documented, but this is the most accurate
  # source of information on error codes.
  ERROR_REFERENCE = "https://github.com/mongodb/mongo/blob/master/docs/errors.md"

  # Generic error class for exceptions related to connection failures.
  class ConnectionError < StandardError; end

  class ReplicaSetReconfigured < StandardError; end

  # Generic error class for exceptions generated on the remote MongoDB
  # server.
  class MongoError < StandardError; end

  # Exception class for exceptions generated as a direct result of an
  # operation, such as a failed insert or an invalid command.
  class OperationFailure < MongoError

    # @return the command that generated the error
    attr_reader :command

    # @return [Hash] the details about the error
    attr_reader :details

    # Create a new operation failure exception.
    #
    # @param command the command that generated the error
    # @param [Hash] details the details about the error
    def initialize(command, details)
      @command = command
      @details = details

      super build_message
    end

    private

    def build_message
      "The operation: #{command.inspect}\n#{error_message}"
    end

    def error_message
      err = details["err"] || details["errmsg"] || details["$err"]

      if code = details["code"]
        "failed with error #{code}: #{err.inspect}\n\n" <<
          "See #{ERROR_REFERENCE}\nfor details about this error."
      else
        "failed with error #{err.inspect}"
      end
    end
  end

  # A special kind of OperationFailure, raised when Mongo sets the
  # :query_failure flag on a query response.
  class QueryFailure < OperationFailure; end

end
