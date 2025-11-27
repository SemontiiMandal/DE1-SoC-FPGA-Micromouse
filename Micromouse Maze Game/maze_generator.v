module maze_generator (
    input  wire        clk,
    input  wire        reset,
    output reg         done,
    output reg [624:0] maze
);

    localparam WALL = 1'b0;
    localparam PATH = 1'b1;


    function automatic [9:0] idx;
        input [4:0] x;
        input [4:0] y;
        begin
            idx = y*10'd25 + x;
        end
    endfunction

    
    reg inited;

    integer x, y;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            inited <= 1'b0;
            done   <= 1'b0;
            maze   <= {625{1'b0}}; 
          
            for (y = 0; y < 25; y = y + 1) begin
                for (x = 0; x < 25; x = x + 1) begin
                    if (x == 0 || x == 24 || y == 0 || y == 24)
                        maze[idx(x,y)] <= WALL;
                    else
                        maze[idx(x,y)] <= PATH; 
                end
            end

  

            
            for (x = 3; x <= 21; x = x + 1) begin
                if (x != 12) maze[idx(x, 6)] <= WALL;
            end

            
            for (y = 8; y <= 20; y = y + 1) begin
                if (y != 12) maze[idx(6, y)] <= WALL;
            end

            
            for (y = 4; y <= 18; y = y + 1) begin
                if (y != 10) maze[idx(18, y)] <= WALL;
            end

            
            for (x = 4; x <= 8; x = x + 1) begin
                if (x != 6) maze[idx(x, 3)] <= WALL;
            end

           
            for (x = 8; x <= 16; x = x + 1) begin
                if (x != 12) maze[idx(x, 12)] <= WALL;
            end

            for (x = 4; x <= 22; x = x + 1) begin
                if (x != 10 && x != 16) maze[idx(x, 18)] <= WALL;
            end

           
            maze[idx(9, 9)]  <= WALL;
            maze[idx(10, 10)]<= WALL;
            maze[idx(11, 11)]<= WALL;

            // ensure sprite loc and reasure loc are free
            maze[idx(5'd1, 5'd1)]   <= PATH;
            maze[idx(5'd23, 5'd23)] <= PATH;

           
            inited <= 1'b1;
            done   <= 1'b1; // signal ready
        end
        else begin
            
            done <= 1'b1;
        end
    end

endmodule

