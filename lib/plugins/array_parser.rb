class ArrayParser

    attr_reader :base_type

    #
    # +base_type+ is a DBI::Type that is used to parse the inner types when
    # a non-array one is found.
    #
    # For instance, if you had an array of integer, one would pass
    # DBI::Type::Integer here.
    #
    def initialize(base_type)
        @base_type = base_type
    end

    #
    # Object method. Please note that this is different than most DBI::Type
    # classes! One must initialize an Array object with an appropriate
    # DBI::Type used to convert the indices of the array before this method
    # can be called.
    #
    # Returns an appropriately converted array.
    #
    def parse(obj)
        if obj.nil?
            nil
        elsif obj.index('{') == 0 and obj.rindex('}') == (obj.length - 1)
            convert_array(obj)
        else
            raise "Not an array"
        end
    end

    #
    # Parse a PostgreSQL-Array output and convert into ruby array. This
    # does the real parsing work.
    #
    def convert_array(str)

        array_nesting = 0         # nesting level of the array
        in_string = false         # currently inside a quoted string ?
        escaped = false           # if the character is escaped
        sbuffer = ''              # buffer for the current element
        result_array = ::Array.new  # the resulting Array

        str.each_byte { |char|    # parse character by character
            char = char.chr         # we need the Character, not it's Integer

            if escaped then         # if this character is escaped, just add it to the buffer
                sbuffer += char
                escaped = false
                next
            end

            case char               # let's see what kind of character we have
                #------------- {: beginning of an array ----#
            when '{'
                if in_string then     # ignore inside a string
                    sbuffer += char
                    next
                end

            if array_nesting >= 1 then  # if it's an nested array, defer for recursion
                sbuffer += char
            end
            array_nesting += 1          # inside another array

            #------------- ": string deliminator --------#
            when '"'
                in_string = !in_string

                #------------- \: escape character, next is regular character #
            when "\\"     # single \, must be extra escaped in Ruby
                if array_nesting > 1
                    sbuffer += char
                else
                    escaped = true
                end

                #------------- ,: element separator ---------#
            when ','
                if in_string or array_nesting > 1 then  # don't care if inside string or
                    sbuffer += char                       # nested array
                else
                    if !sbuffer.is_a? ::Array then
                        sbuffer = @base_type.parse(sbuffer)
                    end
                    result_array << sbuffer               # otherwise, here ends an element
                    sbuffer = ''
                end

            #------------- }: End of Array --------------#
            when '}'
                if in_string then                # ignore if inside quoted string
                    sbuffer += char
                    next
                end

                array_nesting -=1                # decrease nesting level

                if array_nesting == 1            # must be the end of a nested array
                    sbuffer += char
                    sbuffer = convert_array( sbuffer )  # recurse, using the whole nested array
                elsif array_nesting > 1          # inside nested array, keep it for later
                    sbuffer += char
                else                             # array_nesting = 0, must be the last }
                    if !sbuffer.is_a? ::Array then
                        sbuffer = @base_type.parse( sbuffer )
                    end

                    result_array << sbuffer unless sbuffer.nil? # upto here was the last element
                end

                #------------- all other characters ---------#
            else
                sbuffer += char                 # simply append
            end
        }
        return result_array
    end # convert_array()
end
