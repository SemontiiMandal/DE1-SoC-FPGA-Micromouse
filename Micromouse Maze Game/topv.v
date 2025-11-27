module topv(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,          // KEY0=reset, KEY1=Up, KEY2=Right, KEY3=Left
    input  wire [9:0]  SW,          

    output wire [9:0]  LEDR,

 
    output wire [7:0]  VGA_R,// VGA Adapter
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    localparam integer H_PIX = 320; // resolution
    localparam integer V_PIX = 240;
    localparam integer CD    = 6;   

   
    wire reset = ~KEY[0];

    // counter divider
    reg [26:0] divclk;
    always @(posedge CLOCK_50) begin
        if (reset) divclk <= 27'd0;
        else       divclk <= divclk + 27'd1;
    end
    wire tick = divclk[7];           // 390 kHz

    // Blink for win counter
    reg [25:0] hb;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) hb <= 26'd0;
        else       hb <= hb + 26'd1; // 3Hz
    end

   
    wire        maze_done;
    wire [624:0] maze_bits;

    maze_generator u_gen (tick,reset,maze_done,maze_bits);

    wire up    = ~KEY[1];
    wire right = ~KEY[2];
    wire left  = ~KEY[3];
    wire down  =  SW[0];

    reg [3:0] direction;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset)         direction <= 4'b0000;
        else if (maze_done) direction <= {left, down, right, up};
        else               direction <= 4'b0000;
    end

    wire [7:0] player_x;
    wire [7:0] player_y;

    player_controller u_player (tick,maze_done,reset, maze_bits,direction, player_x, player_y);

    localparam [4:0] TREASURE_X = 5'd23; // Win
    localparam [4:0] TREASURE_Y = 5'd23;

    wire at_treasure = (player_x[4:0]==TREASURE_X) && (player_y[4:0]==TREASURE_Y);
    reg  win_latched;
    always @(posedge CLOCK_50 ) begin
        if (reset)         win_latched <= 1'b0;
        else if (at_treasure) win_latched <= 1'b1;
    end

	 // 320*240 rectangle
    reg [8:0] px;  // 0..319
    reg [7:0] py;  // 0..239


    always @(posedge CLOCK_50) begin
        if (reset) begin
            px <= 'd0; py <= 'd0;
        end else begin
            if (px == H_PIX-1) begin
                px <= 'd0;
                py <= (py == V_PIX-1) ? 'd0 : (py + 1'b1);
            end else begin
                px <= px + 1'b1;
            end
        end
    end

    localparam integer CELL_SIZE = (H_PIX==640) ? 16 : 12; 
    localparam integer START_X   = (H_PIX - 25*CELL_SIZE)/2;
    localparam integer START_Y   = (V_PIX - 25*CELL_SIZE)/2;

    wire in_maze_box =
        (px >= START_X) && (px < START_X + 25*CELL_SIZE) &&
        (py >= START_Y) && (py < START_Y + 25*CELL_SIZE);

    wire [9:0] rel_x = px - START_X;
    wire [9:0] rel_y = py - START_Y;

    wire [4:0] tile_x = rel_x / CELL_SIZE;
    wire [4:0] tile_y = rel_y / CELL_SIZE;

    wire [9:0] maze_index = tile_y * 10'd25 + tile_x;

    // Border
    wire on_border = in_maze_box && (
        (px == START_X) ||
        (px == START_X + 25*CELL_SIZE - 1) ||
        (py == START_Y) ||
        (py == START_Y + 25*CELL_SIZE - 1)
    );

    // Sprite and Treasure FOld
    wire is_player_cell   = in_maze_box && (tile_x == player_x[4:0]) && (tile_y == player_y[4:0]);
    wire is_treasure_cell = in_maze_box && (tile_x == TREASURE_X)     && (tile_y == TREASURE_Y);

    // COlor
    wire [CD-1:0] color;

    // 2-2-2 RGB
    localparam [CD-1:0] C_BLACK = 6'b00_00_00;
    localparam [CD-1:0] C_WHITE = 6'b11_11_11;
    localparam [CD-1:0] C_RED   = 6'b11_00_00;
    localparam [CD-1:0] C_CYAN  = 6'b00_11_11;
    localparam [CD-1:0] C_GOLD  = 6'b11_11_00;
    localparam [CD-1:0] C_DGREY = 6'b01_01_01;

    wire blink = hb[24]; // ~3 Hz when win

    reg [CD-1:0] color_sel;
    always @* begin
        if (win_latched && blink)       color_sel = C_CYAN;     // flash
        else if (on_border)             color_sel = C_RED;
        else if (is_player_cell)        color_sel = C_CYAN;
        else if (is_treasure_cell)      color_sel = C_GOLD;
        else if (in_maze_box)           color_sel = (maze_bits[maze_index]) ? C_BLACK : C_RED;
        else                            color_sel = C_BLACK;
    end
    assign color = color_sel;

	 // VGA stuff
    wire [8:0] X_BUS = px[8:0];
    wire [7:0] Y_BUS = py[7:0];
	 
    vga_adapter VGA (
        ~reset,
        CLOCK_50,
      color,
      X_BUS,
       Y_BUS,
      1'b1,
        VGA_R,
        VGA_G,
       VGA_B,
       VGA_HS,
       VGA_VS,
       VGA_BLANK_N,
       VGA_SYNC_N,
    VGA_CLK
    );
`
    defparam VGA.RESOLUTION  = "320x240";
    defparam VGA.COLOR_DEPTH = 6;
`
    assign LEDR = {maze_done, win_latched, SW[7:0]};

endmodule
