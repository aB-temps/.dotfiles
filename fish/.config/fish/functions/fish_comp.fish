function fish_comp
    # Check for at least one argument
    if test (count $argv) -eq 0
        echo "Usage: fish_comp version1 version2 ... (e.g., 98 11 20)"
        return
    end

    # Compile for each specified version
    for ver in $argv
        switch $ver
            case 98
                c++ -std=c++98 "$F".cpp -o "$F"98
                if test $status -eq 0
                    echo -e "\033[32mC++98: compiled\033[0m"  # Green
                else
                    echo -e "\033[31mC++98: failed\033[0m"  # Red
                    echo "Errors:"
                    cat error_log.txt  # Uncomment if using an error log
                end

            case 11
                c++ -std=c++11 "$F".cpp -o "$F"11
                if test $status -eq 0
                    echo -e "\033[32mC++11: compiled\033[0m"  # Green
                else
                    echo -e "\033[31mC++11: failed\033[0m"  # Red
                    echo "Errors:"
                    cat error_log.txt  # Uncomment if using an error log
                end

            case 20
                c++ -std=c++20 "$F".cpp -o "$F"20
                if test $status -eq 0
                    echo -e "\033[32mC++20: compiled\033[0m"  # Green
                else
                    echo -e "\033[31mC++20: failed\033[0m"  # Red
                    echo "Errors:"
                    cat error_log.txt  # Uncomment if using an error log
                end

            # # If the version is invalid
            # case '*'
            #     echo -e "\033[31mInvalid version: $ver\033[0m"  # Red
        end
    end
    
    # Execute existing binaries and display their execution time and status
    for ver in $argv
        set exec_name "$F$ver"
        if test -f "$exec_name"
            # Measure time using 'date' for nanoseconds
            set start_time (date +%s%N)  # Start time in nanoseconds
            ./"$exec_name"
            set end_time (date +%s%N)  # End time in nanoseconds
            set duration (math "$end_time - $start_time")  # Duration in nanoseconds
            
            echo "C++$ver: executed with return code $status in $duration ns"
        else
            echo "C++$ver: no executable found"
        end
    end
end

