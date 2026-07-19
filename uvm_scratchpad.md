Creating an environment ```my_env``` and a module ```tb_top``` to run ```my_env``` and print a message:

```
import uvm_pkg::*;
`include "uvm_macros.svh"

class my_env extends uvm_env;
  `uvm_component_utils (my_env)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction:new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
  
  task run_phase(uvm_phase phase);
    `uvm_info(get_name(), $sformatf("Konnichiwa"), UVM_LOW);
  endtask: run_phase
      
endclass: my_env
  
module tb_top;
  
  initial begin
    run_test("base_test");
  end
  
endmodule
